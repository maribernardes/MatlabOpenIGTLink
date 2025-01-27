%% Receiver function example
function testReceiveMessage()
    global i;
    clc; close all;

    % Set IP socket and number of messages to receive
    N = 1;
    sock = igtlConnect('127.0.0.1', 18944);
    receiver = OpenIGTLinkMessageReceiver(sock, @onRxStatusMessage, @onRxStringMessage, @onRxTransformMessage, @onRxPointMessage);
    for i=1:N
        receiver.readMessage();
    end
    igtlDisconnect(sock);
end

%% Callback when STATUS message is received and processed
% Currently, only prints received value
function onRxStatusMessage(deviceName, text)
    global i
    disp(['Received STATUS message: ', deblank(deviceName),  ' = ', text]);
    i = i+1; % Not counting this message
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