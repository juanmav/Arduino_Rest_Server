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

This Example was also modified by Juan Manuel Vicente adding some logic.(9 July 2014)

**********************************************************************/

#include <config_rest.h>
#include <rest_server.h>
#include <SPI.h>
#include <Ethernet.h>

#define SERVICES_COUNT    14
#define SERVICES_IN_COUNT 6
#define SERVICES_OUT_A_COUNT 4
#define SERVICES_OUT_D_COUNT 4
#define CRLF "\r\n"

/*
  - Analog 0 to 5
  
  0 to SERVICES_IN_COUNT
  
  - OUT PWN 6 to 9
  
  SERVICES_IN_COUNT to SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT
  
  - OUT D 10 to 13
  
  SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT to SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT + SERVICES_OUT_D_COUNT
*/

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

// Reserved Pins for W500 Ethernet Shield
// 10, 11, 12, y 13 (SPI)

// input and output pin assignments
int service_get_pins [] = {A0, A1, A2, A3, A4, A5};
// PWM outputs
int service_a_set_pins [] = {3,5,6,9};
// Digitals OutPuts
int service_d_set_pins [] = {2,4,7,8};

// method that register the resource_descriptions with the request_server
// it is important to define this array in its own method so that it will
// be discarted from the Arduino's RAM after the registration.
void register_rest_server() {
    // Este array esta pensando en orden
    // Primero los service_get_pins y luego los service_set_pins.
    resource_description_t resource_description [SERVICES_COUNT] = {
        {"an_0",     false,     {0, 1024}},
        {"an_1",     false,     {0, 1024}},
        {"an_2",     false,     {0, 1024}},
        {"an_3",     false,     {0, 1024}},
        {"an_4",     false,     {0, 1024}},
        {"an_5",     false,     {0, 1024}},
        {"pwm_3",     true,     {0, 255}},
        {"pwm_5",     true,     {0, 255}},
        {"pwm_6",     true,     {0, 255}},
        {"pwm_9",     true,     {0, 255}},
        {"dig_2",     true,     {0, 1}},
        {"dig_4",     true,     {0, 1}},
        {"dig_7",     true,     {0, 1}},
        {"dig_8",     true,     {0, 1}}
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
    for(int i = 0; i < SERVICES_OUT_A_COUNT; i++) {
        pinMode(service_a_set_pins[i], OUTPUT);
    }
    for(int i = 0; i < SERVICES_OUT_D_COUNT; i++) {
        pinMode(service_d_set_pins[i], OUTPUT);
    }
    
    //POST_WITH_GET
    request_server.set_post_with_get(true);
    // register resources with resource_server
    register_rest_server();
    // Debug
    Serial.begin(9600);
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
    Serial.println("Read Data");
    for (int j = 0; j < SERVICES_IN_COUNT; j++) {
      request_server.resource_set_state(j, analogRead(service_get_pins[j]));
      Serial.println(j);
    }
}

void write_data() {
    Serial.println("Write Data");
    for (int j = SERVICES_IN_COUNT; j < SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT; j++) {
      analogWrite(service_a_set_pins[j - SERVICES_IN_COUNT], request_server.resource_get_state(j));
      Serial.println(j);
    }
    for (int j = SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT; j < SERVICES_IN_COUNT + SERVICES_OUT_A_COUNT + SERVICES_OUT_D_COUNT; j++) {
      digitalWrite(service_d_set_pins[j - SERVICES_IN_COUNT - SERVICES_OUT_A_COUNT], request_server.resource_get_state(j));
      Serial.println(j);
    }
}
