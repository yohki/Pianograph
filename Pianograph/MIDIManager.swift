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
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8)
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8)
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
        
        for i in 0 ..< numberOfSources {
            let src = MIDIGetSource(i)
            var cfStr: Unmanaged<CFString>?
            let err = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &cfStr)
            if err == noErr {
                if let str = cfStr?.takeRetainedValue() as String? {
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
    }

    func onMIDIMessageReceived(message: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) {

        let packetList: MIDIPacketList = message.pointee
        let n = packetList.numPackets
        //os_log("%i MIDI Message(s) Received", n)
        
        var packet = packetList.packet
        for _ in 0 ..< n {
            // Handle MIDIPacket
            let mes: UInt8 = packet.data.0 & 0xF0
            let ch: UInt8 = packet.data.0 & 0x0F
            if mes == 0x90 && packet.data.2 != 0 {
                // Note On
                os_log("Note ON")
                let noteNo = packet.data.1
                let velocity = packet.data.2
                DispatchQueue.main.async {
                    self.delegate?.noteOn(ch: ch, note: noteNo, vel: velocity)
                }
            } else if (mes == 0x80 || mes == 0x90) {
                // Note Off
                os_log("Note OFF")
                let noteNo = packet.data.1
                let velocity = packet.data.2
                DispatchQueue.main.async {
                    self.delegate?.noteOff(ch: ch, note: noteNo, vel: velocity)
                }
            }
            let packetPtr = MIDIPacketNext(&packet)
            packet = packetPtr.pointee
        }
    }
}
