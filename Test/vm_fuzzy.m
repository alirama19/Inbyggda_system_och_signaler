function [h1,h2,t,u,e] = vm_fuzzy(a,N,dT,v)
% L�ser in stegsvaret p� vattenmodellen (niv� h1 och h2) och reglerar niv�n
% i f�rsta beh�llaren med hj�lp av en P-regulator

% DEL A: Beskrivning av de olika variablerna
% utg�ngsvariablerna (vektorer med n v�rden):
% h1: niv� (h�jd) i beh�llaren 1, ansluten till Ai1 p� Ctrl-boxen
% h2: niv� (h�jd) i beh�llaren 2, ansluten till Ai2 p� Ctrl-boxen
% t: tiden
% e: felv�rde
% u: styrsignal till pumpen
% ing�ngsvariablerna:
% a: arduino-objekt som f�s med funktionen a = arduino('COMxx')
% N: antal sampling
% dT: samplingstiden i sek.
% v: v�rden f�r pumpstyrningen som ska h�llas konstant, stegets h�jd

% DEL B: Arduino-mapping i Ctrl-boxen
% interna motorparameter och analoga ing�ngar
DirA=12; % Riktning som motorn ska snurra
PWMA=3; % PWM-motor signal (intern till motor-shields)
Ai1dp=19; % digital pin for analog in 1
Ai2dp=16; % digital pin for analog in 2
Ai1=5; % anslutning analog in 1, Ai1-10V, v�rdet: 0..20cm <==> 0 .. 1024
Ai2=2; % anslutning analog in 2, Ai2-10V, v�rdet: 0..20cm <==> 0 .. 1024

% DEL C: Initialisering av in- och utg�ngar p� Ctrl-Boxen
a.pinMode(DirA,'output');
a.digitalWrite(DirA,1);   %-OBS: riktningen av motorn f�r inte �ndras, dvs ska alltid vara lika med "1"
a.pinMode(PWMA,'output');
a.analogWrite(PWMA,0); % - b�rjar med att st�nga av motorn, -ska man alltid ocks� g�ra i slutet av programmet
a.pinMode(Ai1dp,'input');
a.pinMode(Ai2dp,'input');


% DEL D: Skapa och initialisera olika variablerna f�r att kunna spara m�tresultat
% skapa vektorer f�r att spara m�tv�rden under experimentet, genom att fylla en vektor med N-nullor
h1 = zeros(1, N); %vektor med N nullor p� en (1) rad som ska fyllas med m�tningar av niv�n i vattentank 1
h2 = zeros(1, N); %vektor med N nullor p� en (1) rad som ska fyllas med m�tningar av niv�n i vattentank 2
u = v*ones(N); %vektor f�r stegsvaret med N v�rden som alla �r lika stor som "v"
t = zeros(1, N); %vektor f�r tiden som en numrering av tidspunkter fr�n 1 till N
e = zeros(1, N);% vektor f�r felv�rde
ok=0; %anv�nds f�r att uppt�cka f�r korta samplingstider


% DEL E: starta stegsvarsexperimentet


for i=1:N %slinga kommer att k�ras N-g�ngar, varje g�ng tar exakt Ts-sekunder
    
    start = cputime; %startar en timer f�r att kunna m�ta tiden f�r en loop
    if ok <0 %testar om samplingen �r f�r kort
        i % sampling time too short!
        disp('samplingstiden �r f�r lite! �k v�rdet f�r Ts');
        return
    end
    
    h1(i)= a.analogRead(Ai1); % m�t niv�n i beh�llaren 1
    h2(i)= a.analogRead(Ai2); % m�t niv�n i beh�llaren 2
    
    t(i)= i; %numrerar samples i tidsvektor
    
    e(i)= v-h1(i); %r?knar ut felv?rdet som differens mellan ?rv?rdet och b?rv?rdet
    
    % REGULATORN
    u(i)=evalfis(h1(i), vm_F);
    u(i)=min(255, round(u(i)));
    
    %online-plot
    plot(t,h1,'k-',t,h2,'r--',t,u,'m:', t,e,'b--');
    
    elapsed=cputime-start; %r�knar �tg�ngen tid i sekunder
    ok=(dT-elapsed); % sparar tidsmarginalen i ok
    
    pause(ok); %pausar resterande samplingstid
    
    % Skriva till utg�ngen
    a.analogWrite(PWMA, u(i));
    
    
end % -for

% experimentet �r f�rdig

% DEL F: avsluta experimentet
a.analogWrite(PWMA,0); % st�ng av pumpen
% plotta en fin slutbild,
plot(t,h1,'k-',t,h2,'r--',t,u,'m:', t,e,'b');
xlabel('samples k')
ylabel('niv�n h1, h2, steg u, error e')
title('PID vattenmodell')
legend('h1 ', 'h2 ', 'u ', 'e')

end