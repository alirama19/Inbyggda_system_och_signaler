function [h1,h2,t,u,e] = vm_fuzzy(a,N,dT,v)
% Läser in stegsvaret på vattenmodellen (nivå h1 och h2) och reglerar nivån
% i första behållaren med hjälp av en P-regulator

% DEL A: Beskrivning av de olika variablerna
% utgångsvariablerna (vektorer med n värden):
% h1: nivå (höjd) i behållaren 1, ansluten till Ai1 på Ctrl-boxen
% h2: nivå (höjd) i behållaren 2, ansluten till Ai2 på Ctrl-boxen
% t: tiden
% e: felvärde
% u: styrsignal till pumpen
% ingångsvariablerna:
% a: arduino-objekt som fås med funktionen a = arduino('COMxx')
% N: antal sampling
% dT: samplingstiden i sek.
% v: värden för pumpstyrningen som ska hållas konstant, stegets höjd

% DEL B: Arduino-mapping i Ctrl-boxen
% interna motorparameter och analoga ingångar
DirA=12; % Riktning som motorn ska snurra
PWMA=3; % PWM-motor signal (intern till motor-shields)
Ai1dp=19; % digital pin for analog in 1
Ai2dp=16; % digital pin for analog in 2
Ai1=5; % anslutning analog in 1, Ai1-10V, värdet: 0..20cm <==> 0 .. 1024
Ai2=2; % anslutning analog in 2, Ai2-10V, värdet: 0..20cm <==> 0 .. 1024

% DEL C: Initialisering av in- och utgångar på Ctrl-Boxen
a.pinMode(DirA,'output');
a.digitalWrite(DirA,1);   %-OBS: riktningen av motorn får inte ändras, dvs ska alltid vara lika med "1"
a.pinMode(PWMA,'output');
a.analogWrite(PWMA,0); % - börjar med att stänga av motorn, -ska man alltid också göra i slutet av programmet
a.pinMode(Ai1dp,'input');
a.pinMode(Ai2dp,'input');


% DEL D: Skapa och initialisera olika variablerna för att kunna spara mätresultat
% skapa vektorer för att spara mätvärden under experimentet, genom att fylla en vektor med N-nullor
h1 = zeros(1, N); %vektor med N nullor på en (1) rad som ska fyllas med mätningar av nivån i vattentank 1
h2 = zeros(1, N); %vektor med N nullor på en (1) rad som ska fyllas med mätningar av nivån i vattentank 2
u = v*ones(N); %vektor för stegsvaret med N värden som alla är lika stor som "v"
t = zeros(1, N); %vektor för tiden som en numrering av tidspunkter från 1 till N
e = zeros(1, N);% vektor för felvärde
ok=0; %används för att upptäcka för korta samplingstider


% DEL E: starta stegsvarsexperimentet


for i=1:N %slinga kommer att köras N-gångar, varje gång tar exakt Ts-sekunder
    
    start = cputime; %startar en timer för att kunna mäta tiden för en loop
    if ok <0 %testar om samplingen är för kort
        i % sampling time too short!
        disp('samplingstiden är för lite! Ök värdet för Ts');
        return
    end
    
    h1(i)= a.analogRead(Ai1); % mät nivån i behållaren 1
    h2(i)= a.analogRead(Ai2); % mät nivån i behållaren 2
    
    t(i)= i; %numrerar samples i tidsvektor
    
    e(i)= v-h1(i); %r?knar ut felv?rdet som differens mellan ?rv?rdet och b?rv?rdet
    
    % REGULATORN
    u(i)=evalfis(h1(i), vm_F);
    u(i)=min(255, round(u(i)));
    
    %online-plot
    plot(t,h1,'k-',t,h2,'r--',t,u,'m:', t,e,'b--');
    
    elapsed=cputime-start; %räknar åtgången tid i sekunder
    ok=(dT-elapsed); % sparar tidsmarginalen i ok
    
    pause(ok); %pausar resterande samplingstid
    
    % Skriva till utgången
    a.analogWrite(PWMA, u(i));
    
    
end % -for

% experimentet är färdig

% DEL F: avsluta experimentet
a.analogWrite(PWMA,0); % stäng av pumpen
% plotta en fin slutbild,
plot(t,h1,'k-',t,h2,'r--',t,u,'m:', t,e,'b');
xlabel('samples k')
ylabel('nivån h1, h2, steg u, error e')
title('PID vattenmodell')
legend('h1 ', 'h2 ', 'u ', 'e')

end