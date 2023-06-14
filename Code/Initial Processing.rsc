/*

*/

Macro "Initial Processing" (Args)
    RunMacro("Build_Networks", Args)
    Throw(0)
    // RunMacro("Area_Type", Args)
    // RunMacro("CapSpd", Args)
    // RunMacro("RouteSystemSetUp", Args)
    return(1)
endmacro