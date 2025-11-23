#include <stddef.h>
#include <stdint.h>

void (*runEchoCallback)(void *callable, void *context);
void *context = NULL;
void *callable = NULL;


void giveContextToC(void (*_runEchoCallback)(void *callable, void *context), void *_context, void *_callable) {
  runEchoCallback = _runEchoCallback;
  context = _context;
  callable = _callable;
}

void callbackFromC() {
    runEchoCallback(callable, context);
}

// typedef struct EchoParams {
//   uint32_t c;
// } EchoParams;
//
// extern void callingInCWithParams(void *context, EchoParams params);
//
// void callbackFromCWithParams() {
//   EchoParams p;
//   p.c = 4;
//   callingInCWithParams(context, p);
// }
