//
//  MIDIManager.swift
//  Pianograph
//
//  Created by OHKI Yoshihito on 2020/05/16.
//  Copyright © 2020 Veronica Software. All rights reserved.
//

import Foundation
import CoreMIDI
import os.log

protocol MIDIManagerDelegate {
    func messageReceived()
    func statusChanged()
}

class MIDIManager {
    
    var numberOfSources = 0
    var sourceName = [String]()
    var delegate: MIDIManagerDelegate?
    
    init() {
        findMIDISources()
    }
    
    func findMIDISources() {
        sourceName.removeAll()
        numberOfSources = MIDIGetNumberOfSources()
        os_log("%i Device(s) found", numberOfSources)
        
        for i in 0...numberOfSources {
            let src = MIDIGetSource(i)
            var strPtr: Unmanaged<CFString>?
            let err = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &strPtr)
            if err == noErr {
                if let str = strPtr?.takeRetainedValue() as String? {
                    sourceName.append(str)
                    os_log("Device #%i: %s", i, str)
                }
            }
        }
    }
    
    func connectMIDIClient(_ index: Int) {
        if 0 <= index && index < sourceName.count {
            // Create MIDI Client
            let name = NSString(string: sourceName[index])
            var client = MIDIClientRef()
            var err = MIDIClientCreateWithBlock(name, &client, onMIDIStatusChanged)
            if err != noErr {
                os_log(.error, "Failed to create client")
                return
            }
            os_log("MIDIClient created")
            
            // Create MIDI Input Port
            let portName = NSString("inputPort")
            var port = MIDIPortRef()
            err = MIDIInputPortCreateWithBlock(client, portName, &port, onMIDIMessageReceived)
            if err != noErr {
                os_log("Failed to create input port")
                return
            }
            os_log("MIDIInputPort created")

            // Connect MIDIEndpoint to MIDIInputPort
            let src = MIDIGetSource(index)
            err = MIDIPortConnectSource(port, src, nil)
            if err != noErr {
                os_log("Failed to connect MIDIEndpoint")
                return
            }
            os_log("MIDIEndpoint connected to InputPort")
        }
    }
    
    func onMIDIStatusChanged(message: UnsafePointer<MIDINotification>) {
        os_log("MIDI Status changed!")
        DispatchQueue.main.async {
            self.delegate?.statusChanged()
        }
    }

    func onMIDIMessageReceived(message: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) {
        os_log("MIDI Message Received!")
        DispatchQueue.main.async {
            self.delegate?.messageReceived()
        }
    }
    
    static func onMIDIReceived() {
        print("Packet Received (Static Func)")
    }
}
