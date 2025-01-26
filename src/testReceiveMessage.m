%% Receiver function example
function testReceiveMessage()
    clc;
    close all;
    % Set IP socket
    sock = igtlConnect('127.0.0.1', 18944);
    % Set receiver and loop for 3 messages
    receiver = OpenIGTLinkMessageReceiver(sock, @onRxStringMessage, @onRxTransformMessage, @onRxPointMessage);
    for i=1:3
        receiver.readMessage();
    end
    igtlDisconnect(sock);
end

%% Callback when STRING message is received and processed
% Currently, only prints received value
function onRxStringMessage(deviceName, text)
  disp(['Received STRING message: ', deblank(deviceName),  ' = ', text]);
end

%% Callback when TRANSFORM message is received and processed
% Currently, only prints received value
function onRxTransformMessage(deviceName, transform)
  disp('Received TRANSFORM message: ');
  disp([deblank(deviceName),  ' = ']);
  disp(transform);
end

%% Callback when POINT message is received and processed
% Currently, only prints received value
function onRxPointMessage(deviceName, array)
  disp('Received POINT message: ');
  disp([deblank(deviceName),  ' = ']);
  disp(array);
end