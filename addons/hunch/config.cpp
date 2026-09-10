class CfgPatches {
    class HUNCH_Core {
        name = "HUNCH - Incoming-fire awareness";
        author = "HUNCH contributors";
        requiredVersion = 2.18;
        requiredAddons[] = {"cba_main", "cba_settings", "A3_UI_F"};
        units[] = {};
        weapons[] = {};
    };
};
class CfgFunctions {
    class HUNCH {
        tag = "HUNCH";
        class Core {
            file = "\hunch\functions";
            class settings {preInit = 1;};
            class init {postInit = 1;};
            class reset {};
            class shutdown {};
            class active {};
            class bindReceiver {};
            class register {};
            class fired {};
            class incoming {};
            class profile {};
            class context {};
            class geometry {};
            class visibility {};
            class perceive {};
            class worker {};
            class emit {};
            class render {};
            class metric {};
            class preview {};
            class resetSettings {};
        };
    };
};
class RscTitles {
    class HUNCH_Overlay {
        idd = -1;
        duration = 1e10;
        fadeIn = 0;
        fadeOut = 0;
        onLoad = "uiNamespace setVariable ['HUNCH_display',_this select 0]";
        onUnload = "uiNamespace setVariable ['HUNCH_display',displayNull]";
        class controls {};
    };
};
