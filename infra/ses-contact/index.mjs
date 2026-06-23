// AWS Lambda (Node 22) behind API Gateway (HTTP API) — sends the portfolio
// contact form via SES.
//
// CORS is handled by the HTTP API's CORS configuration (not here), so this
// function returns no CORS headers — that avoids duplicate Access-Control-
// Allow-Origin values on the response.
//
// Env: TO_ADDRESS (verified recipient), FROM_ADDRESS (verified sender/domain).
import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2'

const ses = new SESv2Client({})

export const handler = async (event) => {
  try {
    const { name, email, message } = JSON.parse(event.body ?? '{}')
    if (!name || !email || !message) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Missing fields' }) }
    }

    await ses.send(
      new SendEmailCommand({
        FromEmailAddress: process.env.FROM_ADDRESS,
        Destination: { ToAddresses: [process.env.TO_ADDRESS] },
        ReplyToAddresses: [email],
        Content: {
          Simple: {
            Subject: { Data: `Portfolio contact from ${name}` },
            Body: { Text: { Data: `From: ${name} <${email}>\n\n${message}` } },
          },
        },
      }),
    )
    return { statusCode: 200, body: JSON.stringify({ ok: true }) }
  } catch (err) {
    console.error(err)
    return { statusCode: 500, body: JSON.stringify({ error: 'Send failed' }) }
  }
}
