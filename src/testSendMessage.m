clc;
close all;

% Start connection
igtlConnection = igtlConnect('127.0.0.1',18944);
sender = OpenIGTLinkMessageSender(igtlConnection);

% % THIS FEATURE IS UNDER DEVELOPMENT - Still not stable 
% % Send a POINT message
% pointList = [1.0, 2.0, 3.0;
%              4.0, 5.0, 6.0;
%              7.0, 8.0, 9.0];
% sender.WriteOpenIGTLinkPointMessage('TEST_POINT', pointList);

% Send a STRING message
msg = 'Hello World!';
sender.WriteOpenIGTLinkStringMessage('StringTest', msg);

% Send a TRANSFORM message
theta = 0; translation = [1.0, 2.0, 3.0];
matrix = [cos(theta), -sin(theta), 0, translation(1);
          sin(theta), cos(theta),  0, translation(2);
          0,          0,           1, translation(3);
          0,          0,           0, 1];
sender.WriteOpenIGTLinkTransformMessage('TransformTest', matrix);

% Close connection
igtlDisconnect(igtlConnection);

