/*
 * File : simjoy.c
 *
 */

#define S_FUNCTION_NAME  simjoy
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"
#include "SDL.h"

/*================*
 * Build checking *
 *================*/

/* Simjoy data */
SDL_Joystick *myjoy; /* The current joystick. */
int joy_index;       /* Joystick number. */
int num_joys;        /* number of joysticks. */
int num_axes;        /* Number of axes. */
int num_buttons;     /* Number of buttons. */
int num_hats;        /* Number of hats */
int num_ports;       /* Number of ports. */
int axis_port;       /* Axis port number. */
int button_port;     /* Button port number. */
int hat_port;        /* Hat port number. */

char *no_joy = "No joysticks found.";
char sdl_error[512];

/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *   Setup sizes of the various vectors.
 */
static void mdlInitializeSizes(SimStruct *S)
{
  char warning_string[30];

  /* SDL initialization */
  if (SDL_Init(SDL_INIT_JOYSTICK | SDL_INIT_NOPARACHUTE) == -1) {
    snprintf(sdl_error, 512, 
	     "Could not initialize SDL: %s", SDL_GetError());
    ssSetErrorStatus(S, sdl_error);
    return;
  }
  num_joys = SDL_NumJoysticks();
  if (num_joys <= 0) {
    ssSetErrorStatus(S, no_joy);
    return;
  }
  
  /* Set parameters */
  ssSetNumSFcnParams(S, 1);
  if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
    return; /* Parameter mismatch will be reported by Simulink */
  }
  
  /* Get parameter */
  joy_index = (int)*mxGetPr(ssGetSFcnParam (S, 0));
  if (joy_index >= num_joys) {
    snprintf(sdl_error, 512, 
	     "Only %d joystick(s) were found. Indexing starts at zero. Joystick %d "
             "does not exist.", num_joys, joy_index);
    ssSetErrorStatus(S, sdl_error);
    return;
  }
  myjoy = SDL_JoystickOpen (joy_index);

  /* Collect joystick data. */
  num_axes = SDL_JoystickNumAxes(myjoy);
  num_buttons = SDL_JoystickNumButtons(myjoy);
  num_hats = SDL_JoystickNumHats(myjoy);
  num_ports = 0;
    
  /* Initialize port numbers */
  axis_port = -1;
  button_port = -1;
  hat_port = -1;
    
  if (!ssSetNumInputPorts(S, 0)) return;
    
  /* Determine ports */
  if (num_axes > 0) {
    axis_port = num_ports;
    num_ports++;
  }
  if (num_buttons > 0) {
    button_port = num_ports;
    num_ports++;
  }
  if (num_hats > 0) {
    hat_port = num_ports;
    num_ports++;
  }
    
  if (!ssSetNumOutputPorts(S, num_ports)) return;
    
  /* Set widths */
  if (num_axes > 0)
    ssSetOutputPortWidth(S, axis_port, num_axes);
  if (num_buttons > 0)
    ssSetOutputPortWidth(S, button_port, num_buttons);
  if (num_hats > 0)
    ssSetOutputPortWidth(S, hat_port, num_hats);      
    
  ssSetNumSampleTimes(S, 1);

  /* Take care when specifying exception free code - see sfuntmpl_doc.c */
  ssSetOptions(S,
	       SS_OPTION_WORKS_WITH_CODE_REUSE |
	       SS_OPTION_EXCEPTION_FREE_CODE |
	       SS_OPTION_USE_TLC_WITH_ACCELERATOR);
}


/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    Specifiy that we inherit our sample time from the driving block.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
  ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
  ssSetOffsetTime(S, 0, 0.0);
  ssSetModelReferenceSampleTimeDefaultInheritance(S); 
}

/* Function: mdlOutputs =======================================================
 * Abstract:
 *    y = 2*u
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
  int_T i;
  real_T *jaxis;
  real_T *jbutt;
  real_T *jhat;

  if (axis_port != -1)
    jaxis = ssGetOutputPortRealSignal(S, axis_port);
  if (button_port != -1)
    jbutt = ssGetOutputPortRealSignal(S, button_port);
  if (hat_port != -1)
    jhat  = ssGetOutputPortRealSignal(S, hat_port);
  
  /* Grab current joystick information. */
  SDL_JoystickUpdate();
  
  for (i = 0; i < num_axes; i++)
    {
      jaxis[i] = (real_T) SDL_JoystickGetAxis(myjoy, i) / 32768.0;
    }
  
  for (i = 0; i < num_buttons; i++)
    {
      jbutt[i] = SDL_JoystickGetButton(myjoy, i);
    }

  for (i = 0; i < num_hats; i++)
    {
      jhat[i] = SDL_JoystickGetHat(myjoy, i);
    }
}


/* Function: mdlTerminate =====================================================
 * Abstract:
 *    No termination needed, but we are required to have this routine.
 */
static void mdlTerminate(SimStruct *S)
{
  SDL_JoystickClose(myjoy);
  SDL_Quit();
}

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
