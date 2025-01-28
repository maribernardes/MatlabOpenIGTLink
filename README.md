MatlabOpenIGTLink
=================
This project provides modular and easy to use implementaion for OpenIGTLink protocol using MATLAB. 
Current verstion is compatible with OpenIGTLink v3 protocol and can send and receive STRING, TRANSFORM and POINT messages.
We will be adding IMAGE messages in the near future. 

It is based on MATLAB bridge implemented by Andras Lasso (socket connection is java based, no need for .mex compilation).

-----------------------------------------

As Standard MATLAB license does not allow multitastking OR multi-threading we can not run receiver and sender at the same time. But, we have tried to make it kind of callback based implementation for
the receiver which may be helpful in managing the message workflow. 
