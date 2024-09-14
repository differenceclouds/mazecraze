/*******************************************************************************************
*
*   LayoutName v1.0.0 - Tool Description
*
*   LICENSE: Propietary License
*
*   Copyright (c) 2022 raylib technologies. All Rights Reserved.
*
*   Unauthorized copying of this file, via any medium is strictly prohibited
*   This project is proprietary and confidential unless the owner allows
*   usage in any other form by expresely written permission.
*
**********************************************************************************************/

#include "raylib.h"

#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

//----------------------------------------------------------------------------------
// Controls Functions Declaration
//----------------------------------------------------------------------------------


//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main()
{
    // Initialization
    //---------------------------------------------------------------------------------------
    int screenWidth = 800;
    int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "layout_name");

    // layout_name: controls initialization
    //----------------------------------------------------------------------------------
    bool WindowBox000Active = true;
    bool Spinner001EditMode = false;
    int Spinner001Value = 0;
    Color ColorPicker002Value = { 0, 0, 0, 0 };
    Color ColorPicker003Value = { 0, 0, 0, 0 };
    bool Spinner002EditMode = false;
    int Spinner002Value = 0;
    bool LabelButton006Pressed = false;
    bool LabelButton007Pressed = false;
    bool LabelButton008Pressed = false;
    //----------------------------------------------------------------------------------

    SetTargetFPS(60);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Implement required update logic
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

            ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR))); 

            // raygui: controls drawing
            //----------------------------------------------------------------------------------
            if (WindowBox000Active)
            {
                WindowBox000Active = !GuiWindowBox((Rectangle){ 0, 0, 312, 216 }, "player setup");
                if (GuiSpinner((Rectangle){ 24, 176, 120, 24 }, NULL, &Spinner001Value, 0, 100, Spinner001EditMode)) Spinner001EditMode = !Spinner001EditMode;
                GuiColorPicker((Rectangle){ 24, 48, 96, 96 }, NULL, &ColorPicker002Value);
                GuiColorPicker((Rectangle){ 168, 48, 96, 96 }, NULL, &ColorPicker003Value);
                if (GuiSpinner((Rectangle){ 168, 176, 120, 24 }, NULL, &Spinner002Value, 0, 100, Spinner002EditMode)) Spinner002EditMode = !Spinner002EditMode;
                GuiLabel((Rectangle){ 24, 152, 72, 24 }, "SPEED");
                LabelButton006Pressed = GuiLabelButton((Rectangle){ 168, 152, 120, 24 }, "SPEED");
                LabelButton007Pressed = GuiLabelButton((Rectangle){ 24, 24, 120, 24 }, "COLOR");
                LabelButton008Pressed = GuiLabelButton((Rectangle){ 168, 24, 120, 24 }, "COLOR");
            }
            //----------------------------------------------------------------------------------

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}

//------------------------------------------------------------------------------------
// Controls Functions Definitions (local)
//------------------------------------------------------------------------------------

