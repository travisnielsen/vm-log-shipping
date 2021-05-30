using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace EventProcessor
{
    public static class ReceiveEvents
    {
        [Function("ReceiveEvents")]
        public static void Run([EventHubTrigger("samples-workitems", Connection = "")] string[] input, FunctionContext context)
        {
            var logger = context.GetLogger("ReceiveEvents");
            logger.LogInformation($"First Event Hubs triggered message: {input[0]}");
        }
    }
}
