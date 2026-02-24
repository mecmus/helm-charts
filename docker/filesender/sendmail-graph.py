#!/usr/bin/env python3
"""
sendmail-graph.py - Drop-in sendmail replacement using Microsoft Graph API.

Reads an RFC 2822 MIME email from stdin and sends it via Graph API using
OAuth2 client_credentials flow.  Designed to work as PHP's sendmail_path.

Usage (php.ini):
    sendmail_path = "/usr/local/bin/sendmail-graph.py -t -i"

Required environment variables:
    GRAPH_TENANT_ID      - Microsoft Entra ID tenant GUID
    GRAPH_CLIENT_ID      - Application (client) ID
    GRAPH_CLIENT_SECRET  - Client secret value
    GRAPH_FROM_ADDRESS   - Shared mailbox address used as sender
"""

import base64
import email
import email.policy
import email.utils
import json
import os
import sys
import urllib.parse
import urllib.request

LOG_PREFIX = "[sendmail-graph]"


def log(msg):
    print(f"{LOG_PREFIX} {msg}", file=sys.stderr)


def get_token(tenant_id, client_id, client_secret):
    """Obtain an OAuth2 access token via client_credentials grant."""
    url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": "https://graph.microsoft.com/.default",
    }).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]


def addr_list(value):
    """Parse a header value into a list of Graph API recipient dicts."""
    if not value:
        return []
    recipients = []
    for display, address in email.utils.getaddresses([value]):
        if not address:
            continue
        entry = {"emailAddress": {"address": address}}
        if display:
            entry["emailAddress"]["name"] = display
        recipients.append(entry)
    return recipients


def build_message(msg, from_address, extra_recipients):
    """Convert an email.message.Message into a Graph API sendMail payload."""
    subject = msg.get("Subject", "")
    to = addr_list(msg.get("To", ""))
    cc = addr_list(msg.get("Cc", ""))
    bcc = addr_list(msg.get("Bcc", ""))
    reply_to = addr_list(msg.get("Reply-To", ""))

    # Merge positional-argument recipients into To
    for addr in extra_recipients:
        entry = {"emailAddress": {"address": addr}}
        if entry not in to:
            to.append(entry)

    # Extract body parts and attachments
    body_text = None
    body_html = None
    attachments = []

    if msg.is_multipart():
        for part in msg.walk():
            ct = part.get_content_type()
            disp = str(part.get("Content-Disposition", ""))
            if "attachment" in disp:
                filename = part.get_filename() or "attachment"
                content = part.get_payload(decode=True) or b""
                attachments.append({
                    "@odata.type": "#microsoft.graph.fileAttachment",
                    "name": filename,
                    "contentBytes": base64.b64encode(content).decode(),
                    "contentType": ct,
                })
            elif ct == "text/html" and body_html is None:
                payload = part.get_payload(decode=True)
                if payload is not None:
                    body_html = payload.decode(
                        part.get_content_charset("utf-8"), errors="replace"
                    )
            elif ct == "text/plain" and body_text is None:
                payload = part.get_payload(decode=True)
                if payload is not None:
                    body_text = payload.decode(
                        part.get_content_charset("utf-8"), errors="replace"
                    )
    else:
        payload = msg.get_payload(decode=True)
        charset = msg.get_content_charset("utf-8")
        decoded = payload.decode(charset, errors="replace") if payload else ""
        if msg.get_content_type() == "text/html":
            body_html = decoded
        else:
            body_text = decoded

    if body_html is not None:
        body_content = body_html
        body_type = "HTML"
    else:
        body_content = body_text or ""
        body_type = "Text"

    # Extract the original From: header set by FileSender (the logged-in user)
    original_from = addr_list(msg.get("From", ""))

    message = {
        "subject": subject,
        "body": {"contentType": body_type, "content": body_content},
        "sender": {"emailAddress": {"address": from_address}},  # shared mailbox (technical sender)
        "toRecipients": to,
    }

    # If FileSender set a From: different from the shared mailbox → "sent on behalf of"
    if (
        original_from
        and original_from[0]["emailAddress"]["address"].lower() != from_address.lower()
    ):
        message["from"] = original_from[0]  # the user who is sharing
    else:
        message["from"] = {"emailAddress": {"address": from_address}}

    if cc:
        message["ccRecipients"] = cc
    if bcc:
        message["bccRecipients"] = bcc
    if reply_to:
        message["replyTo"] = reply_to
    if attachments:
        message["attachments"] = attachments

    return {"message": message, "saveToSentItems": False}


def send_mail(token, from_address, payload):
    """POST the sendMail request to Graph API."""
    url = f"https://graph.microsoft.com/v1.0/users/{urllib.parse.quote(from_address)}/sendMail"
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as resp:
        return resp.status


def main():
    # Parse arguments: ignore -t/-i flags, collect bare email addresses
    extra_recipients = []
    for arg in sys.argv[1:]:
        if arg.startswith("-"):
            continue  # ignore sendmail-compatible flags like -t, -i
        extra_recipients.append(arg)

    # Read configuration from environment
    tenant_id = os.environ.get("GRAPH_TENANT_ID", "")
    client_id = os.environ.get("GRAPH_CLIENT_ID", "")
    client_secret = os.environ.get("GRAPH_CLIENT_SECRET", "")
    from_address = os.environ.get("GRAPH_FROM_ADDRESS", "")

    if not all([tenant_id, client_id, client_secret, from_address]):
        log("ERROR: Missing one or more required environment variables: "
            "GRAPH_TENANT_ID, GRAPH_CLIENT_ID, GRAPH_CLIENT_SECRET, GRAPH_FROM_ADDRESS")
        sys.exit(1)

    # Read the email from stdin
    raw = sys.stdin.buffer.read()
    msg = email.message_from_bytes(raw, policy=email.policy.compat32)

    log(f"Sending email: subject={msg.get('Subject', '')!r} "
        f"to={msg.get('To', '')!r}")

    try:
        token = get_token(tenant_id, client_id, client_secret)
    except Exception as exc:
        log(f"ERROR: Failed to obtain access token: {exc}")
        sys.exit(1)

    payload = build_message(msg, from_address, extra_recipients)

    try:
        status = send_mail(token, from_address, payload)
        log(f"Email sent successfully (HTTP {status})")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        log(f"ERROR: Graph API returned HTTP {exc.code}: {body}")
        sys.exit(1)
    except Exception as exc:
        log(f"ERROR: Failed to send email: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
