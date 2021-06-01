using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace EventProcessor
{
    public static class ReceiveEvents
    {

        [Function("ReceiveEvents")]
        public static void Run([EventHubTrigger("vmlogs", Connection = "EventHubConnectionString")] string[] input, FunctionContext context)
        {
            var logger = context.GetLogger("ReceiveEvents");

            foreach (string message in input)
            {
                if (message.Contains("nginx:"))
                    logger.LogWarning(message);
                else
                    logger.LogInformation(message);
            }
        }
    }
}
