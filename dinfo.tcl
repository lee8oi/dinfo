namespace eval dinfo {
################################################################################
#   Copyright ©2011 lee8oi@gmail.com
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   http://www.gnu.org/licenses/
#
################################################################################
#
#   Dinfo script v1.1 (6-27-11)
#   by: <lee8oi@github><lee8oiOnfreenode>
#   github link: https://github.com/lee8oi/dinfo/blob/master/dinfo.tcl
#
#   Dinfo script is the first 'graduate' from the dukescript volatile
#   experiment. This script is simply an info script. Similar to what 'factoids'
#   are in supybot or 'egglearn' for eggdrop. The public '.info' command has
#   list and retrieval capabilities while the dcc/partyline command '.dinfo'
#   allows owners to add, remove, list info entries as well as backup and
#   restore the info database to/from file.
#
#   Initial channel setup:
#   (enables use of public info command in specified channel)
#    .chanset #channel +dinfo
#
#   Public command syntax:
#    .info ?list|help|<text>?
#
#   DCC (partyline) command syntax:
#    .dinfo ?backup|restore|add|remove|list? ?args?
#
#   Example Usage:
#    (public)
#        <lee8oi> .info
#    <dukelovett> Usage: .info ?list|help|<text>?
#        <lee8oi> .info version
#    <dukelovett> version: dinfo 1.0 by lee8oi@github.
#        <lee8oi> .info list
#    <dukelovett> Info Available: help, version, lee8oi
#        <lee8oi> .info lee8oi
#    <dukelovett> lee8oi: The king of dukelovett.org.
#
#    (console)
#        lee8oi .dinfo
#    dukelovett ~dinfo~ Usage: .dinfo ?backup|restore|add|remove? ?text?
#        lee8oi .dinfo backup
#    dukelovett dinfodb saved.
#        lee8oi .dinfo restore
#    dukelovett dinfodb restored.
#        lee8oi .dinfo add test Just a test info entry.
#    dukelovett ~dinfo~ Info item added.
#        lee8oi .dinfo test
#    dukelovett test: Just a test info entry.
#
#
# Updates:
#   v1.1
#       1. Removed lingering '.hi' command that was left in the code when script
#       graduated from Dukescript Volatile Experiment.
#       2. Added ::dinfo:: namespace.
#       3. Fixed script version references to use variable.
#
################################################################################
#   Experts only below this line.
################################################################################
    variable ver "1.1"
    set ::dinfo::dinfodb(version) "dinfo $ver by lee8oi@github."
    if {[file exist "scripts/dinfodb.tcl"]} {
        source scripts/dinfodb.tcl
    }
}
bind pubm - * ::dinfo::pub_handler
bind dcc n dinfo ::dinfo::dcc_proc
setudef flag dinfo
namespace eval dinfo {    
    proc restoredb {args} {
        # restore from file
        variable ::dinfo::dinfodb
        source scripts/dinfodb.tcl
    }
    proc backupdb {args} {
        # backup dinfodb to file.
        variable ::dinfo::dinfodb
        set fs [open "scripts/dinfodb.tcl" w+]
        # write variable lines for loading namespace vars.
        # create 'array set' lines using array data.
        puts $fs "variable ::dinfo::dinfodb"
        puts $fs "array set dinfodb [list [array get dinfodb]]"
        close $fs;
    }
    proc dcc_proc {handle idx text} {
        # dcc/partyline command
        variable ::dinfo::dinfodb
        variable ::dinfo::ver
        set textarr [split $text]
        set text [string tolower [lindex $textarr 0]]
        switch $text {
            "" {
                # show help.
                putdcc $idx "~dinfo $ver~ Usage: .dinfo ?backup|restore|add|remove? ?args?"
            }
            "backup" {
                # run backup procedure.
                ::dinfo::backupdb
                putdcc $idx "dinfodb saved."
            }
            "restore" {
                # run restore procedure.
                ::dinfo::restoredb
                putdcc $idx "dinfodb restored."
            }
            "add" {
                # add a new info entry.
                set second [lindex $textarr 1]
                set value [lrange $textarr 2 end]
                if {$second != "" && $value != ""} {
                    set dinfodb($second) $value
                    ::dinfo::backupdb
                    putdcc $idx "info item added."
                } else {
                    putdcc $idx "~dinfo $ver~ usage: .dinfo add <name> <text>"
                }
            }
            "remove" {
                # remove info entry
                set second [lindex $textarr 1]
                if {$second != ""} {
                    if {[info exists dinfodb($second)]} {
                        unset dinfodb($second)
                        ::dinfo::backupdb
                        putdcc $idx "info item removed."
                    }
                } else {
                    putdcc $idx "~dinfo $ver~ usage: .dinfo remove <name>"
                }  
            }
            "list" {
                # list existing info entries names.
                set arrayvar ""
                foreach {name value} [array get dinfodb] {
                    lappend arrayvar $name
                }
                #set stringvar [join $arrayvar]
                set cleanvar [regsub -all {[ \t]+} $arrayvar {, }]
                putdcc $idx "info available: $cleanvar"
            }
            default {
                # value isn't part of command. Do search.
                set first [lindex $textarr 0]
                if {[info exists dinfodb($first)]} {
                    putdcc $idx "$first: $dinfodb($first)"
                } else {
                    putdcc $idx "info not available."
                }
            }
        }   
    }
    proc pub_handler {nick userhost handle channel text} {
        if {[channel get $channel dinfo]} {
            variable ::dinfo::ver
            set textarr [split $text]
            set first [string tolower [lindex $textarr 0]]
            switch $first {
                ".info" {
                    variable ::dinfo::dinfodb
                    set second [lindex $textarr 1]
                    if {$second != ""} {
                        switch $second {
                            "list" {
                                # list existing info entries names.
                                set arrayvar ""
                                foreach {name value} [array get dinfodb] {
                                    lappend arrayvar $name
                                }
                                #set stringvar [join $arrayvar]
                                set cleanvar [regsub -all {[ \t]+} $arrayvar {, }]
                                putserv "PRIVMSG $channel :info available: $cleanvar"
                            }
                            default {
                                # value isn't part of command. Do search.
                                if {[info exists dinfodb($second)]} {
                                    putserv "PRIVMSG $channel :${second}: $dinfodb($second)"
                                } else {
                                    putserv "PRIVMSG $channel :info not available."
                                }
                            }
                        }
                    } else {
                        putserv "PRIVMSG $channel :~dinfo $ver~ usage: .info ?list|<text>?" 
                    }
                }
            }
        }
    }
}
putlog "Dinfo script [set ::dinfo::ver] Loaded."