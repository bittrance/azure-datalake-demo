# Azure IoT Hub demo

az extension add --name azure-iot

az iot hub generate-sas-token --resource-group iot-demo --hub-name bittrance-iot-demo-hub --device-id iot-demo-test-1

mosquitto_pub -d -h bittrance-iot-demo-hub.azure-devices.net -p 8883 -i iot-demo-test-1 -u "bittrance-iot-demo-hub.azure-devices.net/iot-demo-test-1/?api-version=2018-06-30" -P "<sas-token>" -t "devices/iot-demo-test-1/messages/events/" -m "hello world" -V mqttv311  -q 1

az storage blob list --account-name bittranceiotdemo --container-name iot-demo-container --output table

