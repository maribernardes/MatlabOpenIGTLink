MatlabOpenIGTLink
=================
This project provides modular and easy to use implementation for OpenIGTLink protocol using MATLAB. 
Current version is compatible with OpenIGTLink v3 protocol and can send and receive STRING, TRANSFORM, POINT and IMAGE messages.
Note that IMAGE message has not been extensively tested. In case of problems, please report so we can fix and improve the code.

DEMO:


https://github.com/user-attachments/assets/e6c3dfb0-af7d-4170-951a-ab3da3c14939



It is based on MATLAB bridge implemented by Andras Lasso (socket connection is java based, no need for .mex compilation).

RTDose example image was extracted from Database available in https://github.com/SlicerRt/SlicerRtData/tree/master/eclipse-8.1.20-phantom-ent

-----------------------------------------

As Standard MATLAB license does not allow multitasking OR multi-threading we can not run receiver and sender at the same time. But, we have tried to make it kind of callback based implementation for the receiver which may be helpful in managing the message workflow. 
