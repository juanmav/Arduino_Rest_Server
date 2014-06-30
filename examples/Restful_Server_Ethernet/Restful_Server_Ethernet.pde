/**********************************************************************
RestServer Ethernet Example

This sketch is an example of how to use the RestSever working with the
Ethernet library. The RestLibrary is a simple library that enables the
Arduino to read and respond to incoming requests that are structured as
restfull requests.

For more information check out the GitHub repository at:
https://github.com/julioterra/Arduino_Rest_Server/wiki

Sketch and library created by Julio Terra - November 20, 2011
http://www.julioterra.com/journal

Ethernet code was based on example created on 18 Dec 2009 by David A. Mellis and
modified on 4 Sep 2010 by Tom Igoe

**********************************************************************/

#include <config_rest.h>
#include <rest_server.h>
#include <SPI.h>
#include <Ethernet.h>

#define SERVICES_COUNT    10
#define SERVICES_IN_COUNT 6
#define SERVICES_OUT_COUNT 4
#define CRLF "\r\n"

// Enter a MAC address and IP address for your Arduino below.
// The IP address will be dependent on your local network:
byte mac[] = {0x90, 0xA2, 0xDA, 0x00, 0x68, 0xF8};
byte ip[] = {192,168,125,200};
byte gateway[] = {192,168,125,1};
byte subnet[] = {255,255,255,0};

// Start a TCP server on port 7999
EthernetServer server(7999);

// Create instance of the RestServer
RestServer request_server = RestServer(Serial);

// input and output pin assignments
int service_get_pins [] = {A0, A1, A2, A3, A4, A5};
int service_set_pins [] = {3,5,6,9};

// method that register the resource_descriptions with the request_server
// it is important to define this array in its own method so that it will
// be discarted from the Arduino's RAM after the registration.
void register_rest_server() {
    // Este array esta pensando en orden
    // Primero los service_get_pins y luego los service_set_pins.
    resource_description_t resource_description [SERVICES_COUNT] = {
        {"a_0",     false,     {0, 1024}},
        {"a_1",     false,     {0, 1024}},
        {"a_2",     false,     {0, 1024}},
        {"a_3",     false,     {0, 1024}},
        {"a_4",     false,     {0, 1024}},
        {"a_5",     false,     {0, 1024}},
        {"pin_3",     true,     {0, 255}},
        {"pin_5",     true,     {0, 255}},
        {"pin_6",     true,     {0, 255}},
        {"pin_9",     true,     {0, 255}}
    };
    request_server.register_resources(resource_description, SERVICES_COUNT);
}

void setup() {
    // start the Ethernet connection and the server:
    Ethernet.begin(mac, ip, gateway, subnet);
    server.begin();
    
    // initialize input and output pins
    for(int i = 0; i < SERVICES_IN_COUNT; i++) {
        pinMode(service_get_pins[i], INPUT);
    }
    for(int i = 0; i < SERVICES_OUT_COUNT; i++) {
        pinMode(service_set_pins[i], OUTPUT);
    }
    //POST_WITH_GET
    request_server.set_post_with_get(true);
    // register resources with resource_server
    register_rest_server();
}

void loop() {
    // listen for incoming clients
    EthernetClient client = server.available();
    
    // CONNECTED TO CLIENT
    if (client) {
        while (client.connected()) {
            
            // get request from client, if available
            if (request_server.handle_requests(client)) {
                read_data();
                write_data();
                request_server.respond();    // tell RestServer: ready to respond
            }
            
            // send data to client, when ready
            if (request_server.handle_response(client)) break;
        }
        // give the web browser time to receive the data and close connection
        delay(1);
        client.stop();
    }
}


void read_data() {
    int pin_array_number = 0;
    for (int j = 0; j < SERVICES_COUNT; j++) {
        if (!request_server.resource_post_enabled(j)) {
            request_server.resource_set_state(j, analogRead(service_get_pins[pin_array_number]));
            pin_array_number++;
        }
    }
}

void write_data() {
    int pin_array_number = 0;
    for (int j = 0; j < SERVICES_COUNT; j++) {
        if (request_server.resource_post_enabled(j)) {
            analogWrite(service_set_pins[pin_array_number], request_server.resource_get_state(j));
            pin_array_number++;
        }
    }
}
