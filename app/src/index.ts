import server from './server'
import defaultLogger from '@byu-oit/logger'
import { Logger } from 'pino'

export const logger: Logger = defaultLogger()

async function run (): Promise<void> {
  let tableName = process.env.dynamodb_table_name ?? null
  if (tableName === null) {
    tableName = 'sg738-fav-color-dev'
  }

  const app = await server(tableName)
  app.listen(8080, () => {
    logger.info('listening on port 8080')
  }).on('error', err => {
    logger.error({ err }, 'Error starting the app')
  })
}

run()
  .then(r => {})
  .catch(err => logger.error({ err }, 'Error in running app'))
