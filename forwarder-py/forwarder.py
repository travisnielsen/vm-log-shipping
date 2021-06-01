import sys
import select
import asyncio
from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub import EventData

# skeleton config parameters
pollPeriod = 0.75 # the number of seconds between polling for new messages
maxAtOnce = 1024  # max nbr of messages that are processed within one batch

producer = ""

def onInit():
    global producer
    producer = EventHubProducerClient.from_connection_string(conn_str="", eventhub_name="vmlogs")

async def onReceive(msgs):
    global producer
    async with producer:
        event_data_batch = await producer.create_batch()

        for msg in msgs:
            print(msg)
            event_data_batch.add(EventData(msg))

        # Send the batch of events to the event hub.
        await producer.send_batch(event_data_batch)

def onExit():
    """ Do everything that is needed to finish processing (e.g.
    close files, handles, disconnect from systems...). This is
    being called immediately before exiting.
    """

"""
-------------------------------------------------------
This is plumbing that DOES NOT need to be CHANGED
-------------------------------------------------------
Implementor's note: Python seems to very agressively
buffer stdout. The end result was that rsyslog does not
receive the script's messages in a timely manner (sometimes
even never, probably due to races). To prevent this, we
flush stdout after we have done processing. This is especially
important once we get to the point where the plugin does
two-way conversations with rsyslog. Do NOT change this!
See also: https://github.com/rsyslog/rsyslog/issues/22
"""
onInit()
loop = asyncio.get_event_loop()
keepRunning = 1
while keepRunning == 1:
    while keepRunning and sys.stdin in select.select([sys.stdin], [], [], pollPeriod)[0]:
        msgs = []
        msgsInBatch = 0
        while keepRunning and sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            line = sys.stdin.readline()
            if line:
                msgs.append(line)
            else: # an empty line means stdin has been closed
                keepRunning = 0
            msgsInBatch = msgsInBatch + 1
            if msgsInBatch >= maxAtOnce:
                break
        if len(msgs) > 0:
            loop.run_until_complete(onReceive(msgs))
            sys.stdout.flush() # very important, Python buffers far too much!
onExit()