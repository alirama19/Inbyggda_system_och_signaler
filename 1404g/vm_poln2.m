function [h1,h2,t,u,e] = vm_poln2(a,N,dT,v,Kp) %funktionen reglerar niv�n i f�rsta beh�llaren.
% L�ser in stegsvaret p� vattenmodellen (niv� h1 och h2)

% DEL A: Beskrivning av de olika variablerna
% utg�ngsvariablerna (vektorer med n v�rden):
% h1: niv� (h�jd) i beh�llaren 1, ansluten till Ai1 p� Ctrl-boxen
% h2: niv� (h�jd) i beh�llaren 2, ansluten till Ai2 p� Ctrl-boxen
% t: tiden
% u: styrsignal till pumpen
% ing�ngsvariablerna:
% a: arduino-objekt som f�s med funktionen a = arduino('COMxx')
% N: antal sampling
% dT: samplingstiden i sek.
% v: v�rden f�r pumpstyrningen som ska h�llas konstant, stegets h�jd
%Kp: Konstant faktor man multiplicerar med i P-regulatorn (f�rst�rkningen).

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
ok=0; %anv�nds f�r att uppt�cka f�r korta samplingstider
e = zeros(1, N);

gravity=9.82; % garvitetskonstant
TankArean=0.0028; % Arean i tanken
areanAvUtflode=(7*10^-6); % Arean f�r h�let av utfl�det
n2=512;
borvarde = 512; % Givet - 1024/2


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
%Pz=1;	
Pz = 1 - 0.8 - 0.15;
%Bz=(Kp*dT)/TankArean;
Bz = (Kp*dT)/TankArean*areanAvUtflode*sqrt(gravity/(2*n2))
Az = 1 + ( (areanAvUtflode*dT*sqrt(2*gravity)) / (TankArean*2*sqrt(n2)) - 1 );

Kr = 1 / Bz;
Cz = 1;
Dz = (Pz-Az) / Bz;

  e(i)= ((borvarde+Kr-Dz)*Cz)-h2(i); %r�knar ut felv�rdet som differens mellan �rv�rdet och b�rv�rdet
    
    % REGULATORN
    u(i)=Kp*e(i);
    u(i)=min(255, round(u(i)));
    if u(i) < 0
        u(i) = 0;
    end
    
    % Skriva till utg�ngen
    a.analogWrite(PWMA, u(i));

    %online-plot
    plot(t,h1,'k-',t,h2,'r--',t,u,'m:',t,e,'b');
    
    
    elapsed=cputime-start; %r�knar �tg�ngen tid i sekunder
    ok=(dT-elapsed); % sparar tidsmarginalen i ok
    
    pause(ok); %pausar resterande samplingstid

  end % -for
  
  % experimentet �r f�rdig

% DEL F: avsluta experimentet
  a.analogWrite(PWMA,0); % st�ng av pumpen
  % plotta en fin slutbild, 
  plot(t,h1,'k-',t,h2,'r--',t,u,'m:',t,e,'b');
  xlabel('samples k')
  ylabel('Niv�n i vattentank h1, h2, stegsvar u och felv�rde e')
  title('Deadbeat-reglering tank2')
  legend('h1 ', 'h2 ', 'u ','e')

end

