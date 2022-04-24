// implement control methods

//! params[in] type - true for fast forward, false for rewind
//! params[in] seconds - number of seconds to fast forward or rewind
void DemoForwardOrFallback(bool type, int seconds) {
    int ticks = seconds * g_iServerTickrate;
    
}