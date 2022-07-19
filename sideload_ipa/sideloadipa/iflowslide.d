module sideloadipa.iflowslide;

import gtk.Widget;

import sideloadipa.loginassistant;

interface IFlowSlide {
    string title() shared;
    shared(IFlowSlide) run() shared;
    void setBusy(bool busy) shared;
}
