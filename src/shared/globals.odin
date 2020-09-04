package shared

WINDOW_SIZE_X :: 1920;
WINDOW_SIZE_Y :: 1080;

Current_Game_State := Game_State.Initializing;

Game_State :: enum {
    Initializing,
    
    Login_Screen,
    Character_Select,
    In_Game,
}