# Azure IoT Hub demo

az extension add --name azure-iot

az iot hub device-identity create --hub-name bittrance-iot-demo-hub --device-id iot-demo-test-1

az iot hub generate-sas-token --resource-group iot-demo --hub-name bittrance-iot-demo-hub --device-id iot-demo-test-1

mosquitto_pub -d -h bittrance-iot-demo-hub.azure-devices.net -p 8883 -i iot-demo-test-1 -u "bittrance-iot-demo-hub.azure-devices.net/iot-demo-test-1/?api-version=2018-06-30" -P "<sas-token>" -t "devices/iot-demo-test-1/messages/events/" -m "hello world" -V mqttv311  -q 1

az storage blob list --account-name bittranceiotdemo --container-name iot-demo-container --output table


az eventhubs eventhub authorization-rule keys list --namespace-name iot-demo-namespace --name listen-rule --resource-group iot-demo --eventhub-name iot-demo-eventhub

az storage account show-connection-string --resource-group iot-demo --name bittranceiotdemo

env EVENT_HUB_NAME=iot-demo-eventhub EVENT_HUB_CONNECTION_STRING='...' BLOB_CONNECTION_STRING='...' CONTAINER_NAME='iot-demo-container' ./eventhub-client/client.py