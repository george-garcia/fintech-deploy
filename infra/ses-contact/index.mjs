// AWS Lambda (Node 20) behind API Gateway (HTTP API) — sends the portfolio
// contact form via SES. Replace EmailJS by pointing the portfolio's
// sendContactMessage() at this endpoint.
//
// Env: TO_ADDRESS (verified recipient), FROM_ADDRESS (verified sender/domain),
//      ALLOWED_ORIGIN (e.g. https://georgegarciadev.com)
import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2'

const ses = new SESv2Client({})

export const handler = async (event) => {
  const origin = process.env.ALLOWED_ORIGIN ?? '*'
  const cors = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
  }
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return { statusCode: 204, headers: cors }
  }

  try {
    const { name, email, message } = JSON.parse(event.body ?? '{}')
    if (!name || !email || !message) {
      return { statusCode: 400, headers: cors, body: JSON.stringify({ error: 'Missing fields' }) }
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
    return { statusCode: 200, headers: cors, body: JSON.stringify({ ok: true }) }
  } catch (err) {
    console.error(err)
    return { statusCode: 500, headers: cors, body: JSON.stringify({ error: 'Send failed' }) }
  }
}
