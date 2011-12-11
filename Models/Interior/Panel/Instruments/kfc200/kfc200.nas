####    Bendix-King KFC-200 Flight Director    ####

#Buttons
# HDG ...heading hold
# FD ..... flightdirector on/off
# ALT  ....altitude arm 
# NAV ...VOR / LOC arm
# BC  ....LOC back course 
# APPR ... LOC / GS arm

####  lnav  ####
# 0 = wingleveler
# 1 = heading hold 
# 2 = NAV arm
# 3 = NAV cap
# 4 = APPR arm
# 5 = APPR cap

####  vnav  ####
# 0 = pitch hold
# 1 = ALT arm 
# 2 = ALT cap
# 3 = GS arm
# 4 = GS cap

#KFC200 FlightDirector
# ie: var kfc = KFC200.new("instrumentation/kfc200");
var KFC200 = {
    new : func(prop1){
        m = { parents : [KFC200]};
        m.Llist=["wing-leveler","dg-heading-hold","dg-heading-hold","nav1-hold","dg-heading-hold","nav1-hold","dg-heading-hold","nav1-hold"];
        m.Vlist=["pitch-hold","alt-armed","altitude-hold","pitch-hold","gs1-hold"];
        m.Splist=["","speed-with-throttle"];
		
		m.altarmed=0;
		m.gsarmed=0;
		m.local_lnav=0;
		m.local_vnav=0;
		m.local_spd=0;
		

		m.kfc200 = props.globals.initNode(prop1,1);
        m.pwr = m.kfc200.initNode("fd-on",0,"BOOL");
        m.serviceable = m.kfc200.initNode("serviceable",1,"BOOL");
        m.armed=m.kfc200.initNode("armed",0,"BOOL");
        m.gs_arm=m.kfc200.initNode("gs-arm",0,"BOOL");
		m.alt_armed=m.kfc200.initNode("alt-arm",m.altarmed,"BOOL");
        m.coupled=m.kfc200.initNode("cpld",0,"BOOL");
        m.alert=m.kfc200.initNode("alt-alert",0,"BOOL");
        m.alt=props.globals.initNode("autopilot/settings/target-altitude-ft",0,"DOUBLE");
        m.dhalert=m.kfc200.initNode("dh-alert",0,"BOOL");
        m.DH=m.kfc200.initNode("DH",200,"DOUBLE");
        m.asel=m.kfc200.initNode("alt-preset",0,"DOUBLE");
        m.trim_fail=m.kfc200.initNode("trim-fail",0,"BOOL");
        m.lnav=m.kfc200.initNode("lnav",m.local_lnav,"INT");
        m.vnav=m.kfc200.initNode("vnav",m.local_vnav,"INT");
        m.spd=m.kfc200.initNode("spd",0,"INT");
        m.ap_off=props.globals.initNode("autopilot/locks/passive-mode",1,"BOOL");
        m.HDG = props.globals.initNode("autopilot/locks/heading",m.Llist[0],"STRING");
        m.ALT = props.globals.initNode("/autopilot/locks/altitude",m.Vlist[0],"STRING");
        m.SPD = props.globals.initNode("/autopilot/locks/speed",m.Splist[0],"STRING");
        m.vbar_pitch=m.kfc200.initNode("command-bar-pitch",0,"DOUBLE");
        m.vbar_roll=m.kfc200.initNode("command-bar-roll",0,"DOUBLE");
        m.GS1=props.globals.initNode("/instrumentation/nav/gs-needle-deflection-norm");
        m.DF=props.globals.initNode("instrumentation/nav/heading-needle-deflection");
        m.ROLL=props.globals.initNode("orientation/roll-deg");
        m.PITCH=props.globals.initNode("orientation/pitch-deg");
        m.tgt_ROLL=props.globals.initNode("autopilot/internal/target-roll-deg",0,"DOUBLE");
        m.tgt_PITCH=props.globals.initNode("autopilot/settings/target-pitch-deg",0,"DOUBLE");
		
		m.Llnv = setlistener(m.lnav, func (ln){ m.local_lnav = ln.getValue() ; m.HDG.setValue(m.Llist[m.local_lnav]);},1,0);
		m.Lvnv = setlistener(m.vnav, func (vn){ m.local_vnav = vn.getValue(); m.ALT.setValue(m.Vlist[m.local_vnav]);},1,0);
		m.Lspd = setlistener(m.spd, func (spd){ m.local_spd = spd.getValue();m.SPD.setValue(m.Splist[m.local_spd]);},1,0);
		m.Lpwr = setlistener(m.pwr, func (pwr){ if(!pwr.getValue())m.kill_fd();},1,0);
		m.Lap = setlistener(m.ap_off, func (ap){ if(!ap.getValue())m.tgt_PITCH.setValue(m.PITCH.getValue());},0,0);


	return m;
    },
#### update nav properties ####
    update_nav : func{
		me.dh_check();
        var lnav = me.local_lnav;
        var vnav = me.local_vnav;
        var GS1 = me.GS1.getValue();
        var DF = me.DF.getValue();

        if(getprop("/instrumentation/nav[0]/in-range")){
            if(lnav == 2 or lnav == 4){
                me.armed.setValue(1);
                me.coupled.setValue(0);
                
                if(DF > -9 and DF < 9){
                lnav +=1;
                me.lnav.setValue(lnav);
                me.armed.setValue(0);
                me.coupled.setValue(1);
                }
            }

            if(lnav ==5){
                if(me.gs_arm.getValue()){
                    # the KFC-200 manual doesn't specify the permitted
                    # capture deviation, 20% is a guess.
                    if(getprop("/instrumentation/nav[0]/gs-in-range")){
                        if( GS1< 0.2 and GS1 > -0.2){
                            vnav = 4;
                            me.vnav.setValue(vnav);
                            me.gs_arm.setValue(0);
                        }
                    }
                }
            }
        }

    if(me.altarmed!=0){
        var offset = me.alt_offset();
        if(offset > -990 and offset < 990){
            me.altarmed=0;
			me.alt_armed.setValue(me.altarmed);
			vnav =2;
            me.vnav.setValue(vnav);
            }
        }
var agl=getprop("position/altitude-agl-ft");
if(agl<150)me.ap_off.setValue(1);

var Aroll = me.ROLL.getValue();
if(Aroll==nil)Aroll=0;
if(Aroll<-45 or Aroll > 45)me.ap_off.setValue(1);
var rll =me.tgt_ROLL.getValue();
if(rll==nil)rll=0;
var vroll=(-1*Aroll)+rll;
if(vroll>30)vroll=30;
if(vroll<-30)vroll=-30;
var Apitch = me.PITCH.getValue();
if(Apitch==nil)Apitch=0;
if(Apitch<-45 or Apitch > 45)me.ap_off.setValue(1);
var ptch =me.tgt_PITCH.getValue();
if(ptch==nil)ptch=0;
var vpitch=(-1*Apitch)+ptch;
if(vpitch>60)vpitch=60;
if(vpitch<-30)vpitch=-30;
me.vbar_pitch.setValue(vpitch);
me.vbar_roll.setValue(vroll);
    },

### Decision Hold check ###
    dh_check : func{
        var tst =0;
        var myalt=getprop("position/gear-agl-ft");
        if(myalt < me.DH.getValue())tst = 1;
        me.dhalert.setValue(tst);
    },
### FD off ###
    kill_fd : func{
        me.lnav.setValue(0);
        me.vnav.setValue(0);
        me.spd.setValue(0);
    },
### get Target ALT offset ###
    alt_offset : func{
    var current_alt = getprop("instrumentation/altimeter/indicated-altitude-ft");
    var offset = (current_alt - me.alt.getValue());
    var alert =0;
    if(offset > -1000 and offset < -1000){
        if(offset < -300 and offset > 300)alert = 1;
    }
    me.alert.setValue(alert);
    return(offset);
    },
#### get button inputs ####
    set_mode : func(md){
        var mode = md;
        var idx = 0;

        if(!me.serviceable.getValue()){
            me.local_lnav=0;
			me.lnav.setValue(me.local_lnav);
			me.local_vnav=0;
            me.vnav.setValue(me.local_vnav);
            me.local_spd=0;
			me.spd.setValue(me.local_spd);
            return;
            }

        if(mode == "FD"){
            idx =1;
			var fdtoggle = me.pwr.getValue();
            me.pwr.setValue(1- fdtoggle);
        }elsif(mode == "HDG"){
            idx =1;
            if(me.local_lnav == idx)idx = 0;
            me.lnav.setValue(idx);
        }elsif(mode == "NAV"){
            idx =2;
            if(me.local_lnav == idx)idx = 0;
            me.lnav.setValue(idx);
        }elsif(mode == "ALT"){
            idx =2;
            if(me.local_vnav == idx)idx = 0;
            if(idx ==2){
                me.alt.setValue(getprop("instrumentation/altimeter/mode-c-alt-ft"));
            }
            me.vnav.setValue(idx);
        }elsif(mode == "ALT-ARM"){
            me.altarmed=1-me.altarmed;
			me.alt_armed.setValue(me.altarmed);
			if(me.altarmed!=0){
                me.alt.setValue(me.asel.getValue());
            }
            else{
                me.local_vnav=0;
            }
		}elsif(mode == "APPR"){
            idx =4;
            if(!getprop("/instrumentation/nav/nav-loc"))idx=2;
            if(me.local_lnav == idx)idx = 0;
            me.lnav.setValue(idx);
            if(idx==4){
                if(getprop("/instrumentation/nav/has-gs"))me.gs_arm.setValue(1);
            }
        }elsif(mode == "BC"){
            setprop("instrumentation/nav/back-course-btn",1-getprop("instrumentation/nav/back-course-btn"));
            if(me.local_lnav!=5)setprop("instrumentation/nav/back-course-btn",0);
            return;
        }
    },
#### pitch wheel input ####
    pitch_wheel : func(dir){
        var dr = dir;
        var vm=me.vnav.getValue();
        var scnd =getprop("/sim/time/delta-realtime-sec");
        if(vm==0){
            var temp_pitch = me.tgt_PITCH.getValue();
            var trim = scnd * dr;
            me.tgt_PITCH.setValue(temp_pitch + trim);
            }elsif(vm==2){
                var temp_alt = getprop("autopilot/settings/target-altitude-ft");
                   var trim = (scnd * 10) * dr;
                setprop("autopilot/settings/target-altitude-ft",temp_alt + trim);
            }
    }
};

#####################################

var FD=KFC200.new("/instrumentation/kfc200");

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update,5);
    print("KFC-200 ... Check");
    });

var update = func {
    FD.update_nav();
    settimer(update, 0);
    }
