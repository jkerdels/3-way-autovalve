
//-------------------------------------------------------------------------
// pin configuration

// There are three color-coded buttons in the top-case lid and
// one LED. The buttons are wired such that they close to GND
// when pushed. The LED is wired in series with a suitable resistor
// and is driven directly by one IO pin
const int blue_button_pin  = 11;
const int red_button_pin   = 10;
const int green_button_pin = 12;
const int green_led_pin    = 9;

// the flow meter uses a hall-effect sensor and returns one pulse
// per given amount of water volume (sorta, see calibration table below)
const int flow_meter_pin = 5;

// the motor is driven by an LM 298. So we need the typical in1, in2, and
// enable pins
const int motor_en_A = A3;
const int motor_in_1 = A4;
const int motor_in_2 = A5;

// the two endstops are wired as "close to GND" and indicate whether the
// blue (cold) or red (hot) water valve is closed
const int blue_closed_pin = 3;
const int red_closed_pin  = 4;

// end of pin configuration
//-------------------------------------------------------------------------

// this lookup-table allows to measure the amount of water flowing through
// the flow sensor per sensor tick depending on the time between two ticks,
// i.e., depending on how fast the water is flowing. The values represent
// 100th milliliter per tick, e.g., the first value in the array represents
// 1.22 ml per tick. The array is indexed with the time between two ticks
// measured in milliseconds. If the time between two ticks is longer than
// 100 milliseconds, the last value in the array is used.
// The array was derived by measuring the sensor output for a fixed amount
// of water with different flow rates and then fitting a quadratic 
// polynomial to the resulting values. Given t as time in milliseconds the
// full equation to derive the lookup table is: 
// 100*t / (-0.002117671*t^2 + 0.604550677*t + 0.217819051)

const byte flow_lookup[101] = {
0,122,141,150,154,157,160,162,163,165,166,167,168,169,170,171,172,173,173,
  174,175,176,177,177,178,179,180,181,181,182,183,184,184,185,186,187,188,
  188,189,190,191,192,193,193,194,195,196,197,198,198,199,200,201,202,203,
  204,205,206,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,
  221,222,223,224,226,227,228,229,230,231,232,233,235,236,237,238,239,241,
  242,243,244,246,247,248,250,251,252,254
};

//-------------------------------------------------------------------------
// parameters for auto mode

// these parameters control the heuristic that drives the opening and closing
// of the valves depending on the volume of water used by the washing machine
// and the time past after certain events

// What is the minimum amount of water that has to flow in the beginning
// to be recognized as the water filling of the main phase of the washing program
const unsigned long min_main_flow_volume     = 700000ul; // 7 liters (in hundreds of milliliters)

// What is the minimum time that has to pass after the most recent flow of
// water has come to a stop to recognize the end of water filling of the main phase
const unsigned long min_main_after_flow_time = 240000ul; // 4 minutes (in milliseconds)

// What is the minimum amount of water that has to flow to be recognized as 
// the water filling of a rinse phase of the washing program
const unsigned long min_rinse_flow_volume     = 1000000ul; // 10 liters (in hundreds of milliliters)

// What is the minimum time that has to pass after the most recent flow of
// water has come to a stop to recognize the end of water filling of a rinse phase
const unsigned long min_rinse_after_flow_time = 240000ul; // 4 minutes (in milliseconds)

// The program measures the time of the first rinse phase to identify all subsequent
// rinse phases. What is the amount of time to wait after that measured time span to
// identify the end of the washing program, i.e., how long to wait after the last
// rinse phase to come to the conclusion that the program has ended and we should
// reset to the beginning to be ready for the next load of laundry
const unsigned long rinse_duration_buffer = 180000ul; // 3 minutes (in milliseconds)

// end of parameters for auto mode
//-------------------------------------------------------------------------

// arduino setup routine to initialize all the bells and whistles
void setup() {
  // setting up the buttons
  pinMode(blue_button_pin ,   INPUT_PULLUP);
  pinMode(red_button_pin  ,   INPUT_PULLUP);
  pinMode(green_button_pin,   INPUT_PULLUP);
  pinMode(green_led_pin,      OUTPUT);
  digitalWrite(green_led_pin, LOW);

  // setting up the flow meter input
  pinMode(flow_meter_pin, INPUT);

  // setting up motor output
  pinMode(motor_in_1, OUTPUT);
  digitalWrite(motor_in_1, LOW);

  pinMode(motor_in_2, OUTPUT);
  digitalWrite(motor_in_2, LOW);

  pinMode(motor_en_A, OUTPUT);
  digitalWrite(motor_en_A, LOW);

  // setting up endstops
  pinMode(blue_closed_pin, INPUT_PULLUP);
  pinMode(red_closed_pin , INPUT_PULLUP);  

  // debug
  Serial.begin(115200);
}

// this variable holds the accumulated flow of the
// water flow sensor in 100th of ml
unsigned long accumulated_flow = 0;
byte water_is_flowing = 0;

// variables to control the global state
const byte PS_auto             = 0;
const byte PS_auto_wait        = 5;
const byte PS_manual_red       = 10;
const byte PS_manual_red_wait  = 15;
const byte PS_manual_blue      = 20;
const byte PS_manual_blue_wait = 25;
const byte PS_all_stop         = 30;

const byte PS_idle             = 40;
const byte PS_delay            = 50;
const byte PS_delay_wait       = 55;

byte program_state = PS_all_stop;

byte valve_return = PS_all_stop;

// state parameters
unsigned int PS_delay_duration;

bool expecting_first_flow = false;
unsigned long last_flow_stop      = 0;
unsigned long phase_start         = 0;
unsigned long last_phase_duration = 0;

// since this is a potentially long running application we need to take care
// of the millis() timer coming around after hitting its maximum value. This
// takes place after around 49 days of operation. To avoid this, we modulo
// the time with 2^31 (i.e., "AND" it with 2^31-1) and shift the current time 
// value temporarily in the upper half of our data type when we calculate time 
// spans between "now" and some earlier point in time (see safe_time_delta() 
// function).

// global time
unsigned long now = 0;
// global time modulus
const unsigned long now_mod = 0x80000000; // 2^31
const unsigned long now_and = 0x7FFFFFFF; // 2^31 - 1

inline unsigned long safe_time_delta(const unsigned long now, const unsigned long earlier) {
  return ((now + now_mod) - earlier) & now_and;
}

// main program loop (repeated externally)
void loop() {
  // set global time for this iteration
  now = millis() & now_and;
  // do things
  button_inputs();
  flow_meter_input();
  process_program_state();
}

//--------------------------------------------------------------------------------
// if you want to add or modify functionality of the buttons just add the code in
// the following event functions (button_pressed / button_released). See the
// button_inputs() method to understand when these events are triggered. This method
// already takes care of debouncing the buttons btw.

// button event processing
const byte BS_NONE  = 0;
const byte BS_BLUE  = 1;
const byte BS_RED   = 2;
const byte BS_GREEN = 4;

// the "button_states" byte contains information about the
// states of the other buttons using the bit-positions
// defined above
void blue_pressed(const byte button_states) {
  program_state = PS_manual_blue;
  valve_return  = PS_all_stop;
  digitalWrite(green_led_pin, LOW);
  /*
  Serial.print("blue_pressed, states: ");
  Serial.println(button_states, BIN);
  */
}

// "press_duration" is the time in ms of how long the button was pressed
void blue_released(const byte button_states, const unsigned int press_duration) {
  /*
  Serial.print("blue_released, states: ");
  Serial.print(button_states, BIN);  
  Serial.print(", duration: ");
  Serial.println(press_duration, DEC);
  */
}

void red_pressed(const byte button_states) {
  program_state = PS_manual_red;
  valve_return  = PS_all_stop;
  digitalWrite(green_led_pin, LOW);
  /*
  Serial.print("red_pressed, states: ");
  Serial.println(button_states, BIN);
  */
}

void red_released(const byte button_states, const unsigned int press_duration) {
  /*
  Serial.print("red_released, states: ");
  Serial.print(button_states, BIN);  
  Serial.print(", duration: ");
  Serial.println(press_duration, DEC);  
  */
}

void green_pressed(const byte button_states) {
  /*
  Serial.print("green_pressed, states: ");
  Serial.println(button_states, BIN);
  */
}

void green_released(const byte button_states, const unsigned int press_duration) {
  if (press_duration < 2500) {
    program_state = PS_auto;
  }
  // TODO: create a learning mode entered by holding down the green button for
  // more than 2.5 seconds in which the system learns the different phases of
  // a washing program via manual user input while the washing program is running.
  /*
  Serial.print("green_released, states: ");
  Serial.print(button_states, BIN);  
  Serial.print(", duration: ");
  Serial.println(press_duration, DEC);    
  */
}

//--------------------------------------------------------------------------------
// flow events

// if you want to add or modify what happens when a new flow of water is detected
// or its end, just change these event methods. See flow_meter_input() function
// to understand when these events are triggered. The total accumulated flow
// measured by the sensor is available through the global variable "accumulated_flow"

void new_flow_started() {  
  Serial.println("flow started");
  if (expecting_first_flow) {
    expecting_first_flow  = false;
    last_flow_stop        = now;
    last_phase_duration   = safe_time_delta(now,phase_start);
    phase_start           = now;
  }
}

void flow_stopped(const unsigned long flow_time, const unsigned long flow_volume) {
  
  Serial.print("flow ended, time: ");
  Serial.print(flow_time, DEC);    
  Serial.print(", volume: ");
  Serial.println(flow_volume, DEC);    

  last_flow_stop = now;
}

//--------------------------------------------------------------------------------
// handle program state

// this method controls the overal behavior of the automatic valve, including
// states that deal with manual operation of the valves triggered by pressing
// the red or blue buttons, and the automatic mode that is entered by pressing
// the green button and indicated by the green LED

void process_program_state() {

  // used by some states to control the flow in the state machine
  // in a more flexible way, e.g., the delay state
  static byte return_state = PS_idle;

  static unsigned long delay_start = 0;

  // washing machine states
  const byte EMS_INIT            = 0;
  const byte EMS_START           = 10;
  const byte EMS_MAIN_FILL       = 20;
  const byte EMS_MAIN_WASH       = 30;
  const byte EMS_1ST_RINSE_FILL  = 40;
  const byte EMS_1ST_RINSE_WASH  = 50;
  const byte EMS_NTH_RINSE_FILL  = 60;
  const byte EMS_NTH_RINSE_WASH  = 70;

  static byte est_machine_state = EMS_INIT;

  static unsigned long rinse_wash_start = 0;
  static unsigned long rinse_duration   = 0;
  

  switch (program_state) {

    case PS_auto : {
      Serial.println("entered automatic mode");
      motor_stop();
      // switch on green light
      digitalWrite(green_led_pin, HIGH);
      // initialize estimated machine state
      est_machine_state = EMS_INIT;
      phase_start       = now;
      // check if warm water is closed and open
      // if that is the case
      if (digitalRead(red_closed_pin) == LOW) {
        Serial.println("hot water valve close. Opening...");
        valve_return = PS_auto_wait;
        program_state = PS_manual_red;
      } else {
        program_state = PS_auto_wait;
      }
    } break;

    case PS_auto_wait : {
      switch (est_machine_state) {
        
        case EMS_INIT : {
          Serial.println("waiting for initial flow...");  
          expecting_first_flow = true;
          accumulated_flow     = 0;    
          est_machine_state = EMS_START;
        } break;
        
        case EMS_START : {
          // wait for first flow to occur
          if (expecting_first_flow == false) {
            Serial.println("main fill started");
            est_machine_state = EMS_MAIN_FILL;
          }
        } break;

        case EMS_MAIN_FILL : {
          // wait for end of flow by waiting for at least
          // [min_main_flow_volume] liters of water and [min_main_after_flow_time] after last flow stop
          if ((water_is_flowing == 0) && 
              (accumulated_flow > min_main_flow_volume) && 
              (safe_time_delta(now,last_flow_stop) > min_main_after_flow_time))
          {
            // switch from hot to cold water and wait for rinse
            valve_return         = PS_auto_wait;
            program_state        = PS_manual_blue;
            est_machine_state    = EMS_MAIN_WASH;
            expecting_first_flow = true;
            accumulated_flow     = 0;
            Serial.println("Assuming to be in main wash. Switching to cold water and waiting for 1st rinse fill.");
          }
        } break;

        case EMS_MAIN_WASH : {
          // wait for first rinse flow to occur
          if (expecting_first_flow == false) {
            Serial.print("Main phase took ");
            Serial.print(last_phase_duration / 60000ul);
            Serial.println(" minutes.");
            Serial.println("First rinse fill started.");
            est_machine_state = EMS_1ST_RINSE_FILL;
          }
        } break;

        case EMS_1ST_RINSE_FILL : {
          // wait for end of flow by waiting for at least
          // [min_rinse_flow_volume] liters of water and [min_rinse_after_flow_time] after last flow stop
          if ((water_is_flowing == 0) && 
              (accumulated_flow > min_rinse_flow_volume) && 
              (safe_time_delta(now,last_flow_stop) > min_rinse_after_flow_time))
          {
            // wait for 2nd rinse
            est_machine_state    = EMS_1ST_RINSE_WASH;
            expecting_first_flow = true;
            accumulated_flow     = 0;
            Serial.println("Assuming to be in 1st rinse wash. Waiting for 2nd rinse fill.");
          }
        } break;

        case EMS_1ST_RINSE_WASH : {
          // wait for second rinse flow to occur
          if (expecting_first_flow == false) {
            rinse_duration = last_phase_duration;
            Serial.print("1st rinse phase took ");
            Serial.print(last_phase_duration / 60000ul);
            Serial.println(" minutes.");
            Serial.println("Second rinse fill started.");
            est_machine_state = EMS_NTH_RINSE_FILL;
          }
        } break;

        case EMS_NTH_RINSE_FILL : {
          // wait for end of flow by waiting for at least
          // [min_rinse_flow_volume] liters of water and [min_rinse_after_flow_time] after last flow stop
          if ((water_is_flowing == 0) && 
              (accumulated_flow > min_rinse_flow_volume) && 
              (safe_time_delta(now,last_flow_stop) > min_rinse_after_flow_time))
          {
            // wait for rinse to stop or a further rinse to start
            est_machine_state    = EMS_NTH_RINSE_WASH;
            expecting_first_flow = true;
            accumulated_flow     = 0;
            rinse_wash_start     = now;
            Serial.println("Assuming to be in a rinse wash. Waiting for it to end or a further rinse fill to start.");
          }
        } break;

        case EMS_NTH_RINSE_WASH : {
          // wait for a further rinse flow to occur
          if (expecting_first_flow == false) {
            rinse_duration = last_phase_duration;
            Serial.print("the last rinse phase took ");
            Serial.print(last_phase_duration / 60000ul);
            Serial.println(" minutes.");
            Serial.println("Another rinse fill started.");
            est_machine_state = EMS_NTH_RINSE_FILL;
          } else
          if (safe_time_delta(now,rinse_wash_start) > (rinse_duration + rinse_duration_buffer)) {
            // no further rinse appears to happen, assume we are done
            Serial.println("Assuming end of program. Returning to start.");
            program_state = PS_auto;
          }
          
        } break;

      }
    } break;

    
    case PS_manual_red : {
      motor_forward();
      program_state = PS_manual_red_wait;
    } break;

    case PS_manual_red_wait : {
      if (digitalRead(blue_closed_pin) == LOW) {
        PS_delay_duration = 200;
        return_state = valve_return;
        program_state = PS_delay;
      }
    } break;

    case PS_manual_blue : {
      motor_backward();
      program_state = PS_manual_blue_wait;
    } break;

    case PS_manual_blue_wait : {
      if (digitalRead(red_closed_pin) == LOW) {
        PS_delay_duration = 200;
        return_state = valve_return;
        program_state = PS_delay;
      }      
    } break;

    case PS_all_stop : {
      motor_stop();
      program_state = PS_idle;
    } break;

    case PS_idle : {
      
    } break;

    case PS_delay : {
      delay_start = now;
      program_state = PS_delay_wait;
    } break;

    case PS_delay_wait : {
      if (now - delay_start > PS_delay_duration) {
        program_state = return_state;
      }
    } break;

  }
  
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// below here are "only" service functions that do not need to be edited to
// specify the behavior of the system

// read buttons and cause button event functions to be called
void button_inputs() {

  // static time variables for debouncing
  static unsigned long blue_push_time  = 0;
  static unsigned long red_push_time   = 0;
  static unsigned long green_push_time = 0;
 
  const byte debounce_interval = 50;
  
  // static button state
  static byte button_states = BS_NONE;

  // check for button press events and store time
  if (((button_states & BS_BLUE) == 0) && (digitalRead(blue_button_pin) == LOW)) {
    button_states |= BS_BLUE;
    blue_push_time = now;
    blue_pressed(button_states);
  }

  if (((button_states & BS_RED) == 0) && (digitalRead(red_button_pin) == LOW)) {
    button_states |= BS_RED;
    red_push_time = now;
    red_pressed(button_states);
  }

  if (((button_states & BS_GREEN) == 0) && (digitalRead(green_button_pin) == LOW)) {
    button_states |= BS_GREEN;
    green_push_time = now;
    green_pressed(button_states);
  }

  if (((button_states & BS_BLUE) > 0) && (digitalRead(blue_button_pin) == HIGH)) {
    unsigned long down_time = safe_time_delta(now,blue_push_time);
    if (down_time > debounce_interval) {
      button_states &= ~BS_BLUE;
      blue_released(button_states,(const unsigned int)down_time);
    }
  }

  if (((button_states & BS_RED) > 0) && (digitalRead(red_button_pin) == HIGH)) {
    unsigned long down_time = safe_time_delta(now,red_push_time);
    if (down_time > debounce_interval) {
      button_states &= ~BS_RED;
      red_released(button_states,(const unsigned int)down_time);
    }
  }

  if (((button_states & BS_GREEN) > 0) && (digitalRead(green_button_pin) == HIGH)) {
    unsigned long down_time = safe_time_delta(now,green_push_time);
    if (down_time > debounce_interval) {
      button_states &= ~BS_GREEN;    
      green_released(button_states,(const unsigned int)down_time);
    }
  }  
}


void flow_meter_input() {

  static unsigned long flow_begin  = 0;
  static unsigned long flow_volume = 0;
  static unsigned long last_flow_time = now;
  static byte last_val = digitalRead(flow_meter_pin);

  unsigned long delta = safe_time_delta(now,last_flow_time);

  if ((water_is_flowing == 20) && (delta > 2000)) {
    // we have not received flow ticks for two seconds
    // so we assume the flow has stopped
    water_is_flowing = 0;
    flow_stopped(safe_time_delta(now,flow_begin) - delta,flow_volume);
  }
  
  int val = digitalRead(flow_meter_pin);
  if ((val != last_val) && (val == HIGH)) {        
    if (delta < 150) {
      unsigned int cur_flow = delta <= 100 ? flow_lookup[delta] : 297;
      accumulated_flow += cur_flow;
      flow_volume      += cur_flow;
      // wait for at least 20 ticks before we announce that a new
      // flow has started
      if (water_is_flowing < 20) {
        if (++water_is_flowing == 20) {
          flow_begin  = now;
          flow_volume = 0;
          new_flow_started();
        }
      }
    } else if (delta > 2000){
      // this is (probably) a new flow, as the
      // last measurement is "long ago" (5 seconds)
      water_is_flowing = 0;
    }
    last_flow_time = now;
  }
  last_val = val;    
}

void motor_forward() {
  motor_stop();
   
  digitalWrite(motor_in_1, LOW);
  digitalWrite(motor_in_2, HIGH);
  
  digitalWrite(motor_en_A, HIGH);
}

void motor_backward() {
  motor_stop();

  digitalWrite(motor_in_1, HIGH);
  digitalWrite(motor_in_2, LOW);
  
  digitalWrite(motor_en_A, HIGH);
}

void motor_stop() {
  digitalWrite(motor_in_1, LOW);
  digitalWrite(motor_in_2, LOW);
  digitalWrite(motor_en_A, LOW);  
}
