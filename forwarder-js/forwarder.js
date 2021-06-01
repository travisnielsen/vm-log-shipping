#!/usr/bin/nodejs

const { EventHubProducerClient } = require("@azure/event-hubs");
const readLine = require('readline');

const connectionString = "";
const eventHubName = "vmlogs";
const batchOptions = {};

async function main() {

    const producer = new EventHubProducerClient(connectionString, eventHubName);

    var rl = readLine.createInterface({
        input: process.stdin,
        output: process.stdout,
        terminal: false
    });

    rl.on('line', async function(line){
        let batch = await producer.createBatch(batchOptions);
        (await batch).tryAdd({ body: line });
        await producer.sendBatch(batch);
    })

    await producer.close();
}

main();