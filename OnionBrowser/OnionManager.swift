/*
 * Onion Browser
 * Copyright (c) 2012-2017 Mike Tigas
 *
 * This file is part of Onion Browser. See LICENSE file for redistribution terms.
 */

import Foundation

@objc class OnionManager : NSObject {

    @objc static let singleton = OnionManager()

    // Show Tor log in iOS' app log.
    private static let TOR_LOGGING = true

    private static let torBaseConf: TorConfiguration = {

        // Store data in <appdir>/Library/Caches/tor (Library/Caches/ is for things that can persist between
        // launches -- which we'd like so we keep descriptors & etc -- but don't need to be backed up because
        // they can be regenerated by the app)
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .cachesDirectory, in: .userDomainMask)
        let docsDir = dirPaths[0].path

        let dataDir = URL(fileURLWithPath: docsDir, isDirectory: true).appendingPathComponent("tor", isDirectory: true)

        print(dataDir);

        // Create tor data directory if it does not yet exist
        do {
            try FileManager.default.createDirectory(atPath: dataDir.absoluteString, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }

        // Configure tor and return the configuration object
        let configuration = TorConfiguration()
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDir
        configuration.arguments = [
            "--ignore-missing-torrc",
            "--clientonly", "1",
            "--socksport", "39050",
            "--controlport", "127.0.0.1:39060",
            //"--log", "notice stdout",
            "--log", "notice file /dev/null",
            "--clientuseipv4", "1",
            "--clientuseipv6", "1",
            "--ClientPreferIPv6ORPort", "auto",
            "--ClientPreferIPv6DirPort", "auto",
            "--ClientTransportPlugin", "obfs4 socks5 127.0.0.1:47351",
            "--ClientTransportPlugin", "meek_lite socks5 127.0.0.1:47352",
        ]
        return configuration
    }()

    // MARK: - Built-in configuration options

    private static let obfs4Bridges = [
        "obfs4 154.35.22.10:15937 8FB9F4319E89E5C6223052AA525A192AFBC85D55 cert=GGGS1TX4R81m3r0HBl79wKy1OtPPNR2CZUIrHjkRg65Vc2VR8fOyo64f9kmT1UAFG7j0HQ iat-mode=0",
        "obfs4 198.245.60.50:443 752CF7825B3B9EA6A98C83AC41F7099D67007EA5 cert=xpmQtKUqQ/6v5X7ijgYE/f03+l2/EuQ1dexjyUhh16wQlu/cpXUGalmhDIlhuiQPNEKmKw iat-mode=0",
        "obfs4 192.99.11.54:443 7B126FAB960E5AC6A629C729434FF84FB5074EC2 cert=VW5f8+IBUWpPFxF+rsiVy2wXkyTQG7vEd+rHeN2jV5LIDNu8wMNEOqZXPwHdwMVEBdqXEw iat-mode=0",
        "obfs4 109.105.109.165:10527 8DFCD8FB3285E855F5A55EDDA35696C743ABFC4E cert=Bvg/itxeL4TWKLP6N1MaQzSOC6tcRIBv6q57DYAZc3b2AzuM+/TfB7mqTFEfXILCjEwzVA iat-mode=1",
        "obfs4 83.212.101.3:50002 A09D536DD1752D542E1FBB3C9CE4449D51298239 cert=lPRQ/MXdD1t5SRZ9MquYQNT9m5DV757jtdXdlePmRCudUU9CFUOX1Tm7/meFSyPOsud7Cw iat-mode=0",
        "obfs4 109.105.109.147:13764 BBB28DF0F201E706BE564EFE690FE9577DD8386D cert=KfMQN/tNMFdda61hMgpiMI7pbwU1T+wxjTulYnfw+4sgvG0zSH7N7fwT10BI8MUdAD7iJA iat-mode=2",
        "obfs4 154.35.22.11:16488 A832D176ECD5C7C6B58825AE22FC4C90FA249637 cert=YPbQqXPiqTUBfjGFLpm9JYEFTBvnzEJDKJxXG5Sxzrr/v2qrhGU4Jls9lHjLAhqpXaEfZw iat-mode=0",
        "obfs4 154.35.22.12:80 00DC6C4FA49A65BD1472993CF6730D54F11E0DBB cert=N86E9hKXXXVz6G7w2z8wFfhIDztDAzZ/3poxVePHEYjbKDWzjkRDccFMAnhK75fc65pYSg iat-mode=0",
        "obfs4 154.35.22.13:443 FE7840FE1E21FE0A0639ED176EDA00A3ECA1E34D cert=fKnzxr+m+jWXXQGCaXe4f2gGoPXMzbL+bTBbXMYXuK0tMotd+nXyS33y2mONZWU29l81CA iat-mode=0",
        "obfs4 154.35.22.10:80 8FB9F4319E89E5C6223052AA525A192AFBC85D55 cert=GGGS1TX4R81m3r0HBl79wKy1OtPPNR2CZUIrHjkRg65Vc2VR8fOyo64f9kmT1UAFG7j0HQ iat-mode=0",
        "obfs4 154.35.22.10:443 8FB9F4319E89E5C6223052AA525A192AFBC85D55 cert=GGGS1TX4R81m3r0HBl79wKy1OtPPNR2CZUIrHjkRg65Vc2VR8fOyo64f9kmT1UAFG7j0HQ iat-mode=0",
        "obfs4 154.35.22.11:443 A832D176ECD5C7C6B58825AE22FC4C90FA249637 cert=YPbQqXPiqTUBfjGFLpm9JYEFTBvnzEJDKJxXG5Sxzrr/v2qrhGU4Jls9lHjLAhqpXaEfZw iat-mode=0",
        "obfs4 154.35.22.11:80 A832D176ECD5C7C6B58825AE22FC4C90FA249637 cert=YPbQqXPiqTUBfjGFLpm9JYEFTBvnzEJDKJxXG5Sxzrr/v2qrhGU4Jls9lHjLAhqpXaEfZw iat-mode=0",
        "obfs4 154.35.22.9:12166 C73ADBAC8ADFDBF0FC0F3F4E8091C0107D093716 cert=gEGKc5WN/bSjFa6UkG9hOcft1tuK+cV8hbZ0H6cqXiMPLqSbCh2Q3PHe5OOr6oMVORhoJA iat-mode=0",
        "obfs4 154.35.22.9:80 C73ADBAC8ADFDBF0FC0F3F4E8091C0107D093716 cert=gEGKc5WN/bSjFa6UkG9hOcft1tuK+cV8hbZ0H6cqXiMPLqSbCh2Q3PHe5OOr6oMVORhoJA iat-mode=0",
        "obfs4 154.35.22.9:443 C73ADBAC8ADFDBF0FC0F3F4E8091C0107D093716 cert=gEGKc5WN/bSjFa6UkG9hOcft1tuK+cV8hbZ0H6cqXiMPLqSbCh2Q3PHe5OOr6oMVORhoJA iat-mode=0",
        "obfs4 154.35.22.12:4304 00DC6C4FA49A65BD1472993CF6730D54F11E0DBB cert=N86E9hKXXXVz6G7w2z8wFfhIDztDAzZ/3poxVePHEYjbKDWzjkRDccFMAnhK75fc65pYSg iat-mode=0",
        "obfs4 154.35.22.13:16815 FE7840FE1E21FE0A0639ED176EDA00A3ECA1E34D cert=fKnzxr+m+jWXXQGCaXe4f2gGoPXMzbL+bTBbXMYXuK0tMotd+nXyS33y2mONZWU29l81CA iat-mode=0",
        "obfs4 192.95.36.142:443 CDF2E852BF539B82BD10E27E9115A31734E378C2 cert=qUVQ0srL1JI/vO6V6m/24anYXiJD3QP2HgzUKQtQ7GRqqUvs7P+tG43RtAqdhLOALP7DJQ iat-mode=1",
        "obfs4 85.17.30.79:443 FC259A04A328A07FED1413E9FC6526530D9FD87A cert=RutxZlu8BtyP+y0NX7bAVD41+J/qXNhHUrKjFkRSdiBAhIHIQLhKQ2HxESAKZprn/lR3KA iat-mode=0",
        "obfs4 38.229.1.78:80 C8CBDB2464FC9804A69531437BCF2BE31FDD2EE4 cert=Hmyfd2ev46gGY7NoVxA9ngrPF2zCZtzskRTzoWXbxNkzeVnGFPWmrTtILRyqCTjHR+s9dg iat-mode=1"
    ]
    public static let meekAmazonBridges = [
        "meek_lite 0.0.2.0:2 B9E7141C594AF25699E0079C1F0146F409495296 url=https://d2cly7j4zqgua7.cloudfront.net/ front=a0.awsstatic.com"
    ]
    public static let meekAzureBridges = [
        "meek_lite 0.0.2.0:3 97700DFE9F483596DDA6264C4D7DF7641E1E39CE url=https://meek.azureedge.net/ front=ajax.aspnetcdn.com"
    ]

    // MARK: - OnionManager instance

    private let torController = TorController(socketHost: "127.0.0.1", port: 39060)
    private let obfsproxy = ObfsThread()


    private var torThread: TorThread?

    public var torHasConnected: Bool = false
    private var failGuard: DispatchWorkItem?

    private var bridgesId: Int?
    private var customBridges: [String]?
    private var needsReconfiguration: Bool = false

    /**
        Set bridges configuration and evaluate, if the new configuration is actually different
        then the old one.

         - parameter bridgesId: the selected ID as defined in OBSettingsConstants.
         - parameter customBridges: a list of custom bridges the user configured.
    */
    @objc func setBridgeConfiguration(bridgesId: Int, customBridges: [String]?) {
        needsReconfiguration = bridgesId != self.bridgesId ?? USE_BRIDGES_NONE

        if !needsReconfiguration {
            if let oldVal = self.customBridges, let newVal = customBridges {
                needsReconfiguration = oldVal != newVal
            }
            else{
                needsReconfiguration = (self.customBridges == nil && customBridges != nil) ||
                    (self.customBridges != nil && customBridges == nil)
            }
        }

        self.bridgesId = bridgesId
        self.customBridges = customBridges
    }

    @objc func startTor(delegate: OnionManagerDelegate?) {
        cancelFailGuard()
        torHasConnected = false

        if self.torThread == nil {
            let torConf = OnionManager.torBaseConf

            if bridgesId != nil && bridgesId != USE_BRIDGES_NONE {
                // Take default config, add the bridges, and turn on "usebridges 1"
                var args = torConf.arguments!
                args.append("--usebridges")
                args.append("1")

                print("use_bridges = \(String(describing: bridgesId))")

                switch bridgesId! {
                    case USE_BRIDGES_OBFS4:
                        args += bridgeLinesToArgs(OnionManager.obfs4Bridges)
                    case USE_BRIDGES_MEEKAMAZON:
                        args += bridgeLinesToArgs(OnionManager.meekAmazonBridges)
                    case USE_BRIDGES_MEEKAZURE:
                        args += bridgeLinesToArgs(OnionManager.meekAzureBridges)
                    default:
                        if customBridges != nil {
                            args += bridgeLinesToArgs(customBridges!)
                        }
                }

                print("\n\n\(String(describing: args))\n\n");
                torConf.arguments = args
            }

            self.torThread = TorThread(configuration: torConf)
            needsReconfiguration = false

            self.torThread!.start()
            self.obfsproxy.start()

            print("STARTING TOR");
        }
        else {
            if needsReconfiguration {
                if bridgesId == nil || bridgesId == USE_BRIDGES_NONE {
                    // Not using bridges, so null out the "Bridge" conf
                    torController.setConfForKey("usebridges", withValue: "0", completion: { (_, _) in
                    })
                    torController.resetConf(forKey: "bridge", completion: { (_, _) in
                    })
                } else {
                    var bridges:Array<String> = []
                    var confs:[Dictionary<String,String>] = []

                    switch bridgesId! {
                    case USE_BRIDGES_OBFS4:
                        bridges = OnionManager.obfs4Bridges
                    case USE_BRIDGES_MEEKAMAZON:
                        bridges = OnionManager.meekAmazonBridges
                    case USE_BRIDGES_MEEKAZURE:
                        bridges = OnionManager.meekAzureBridges
                    default:
                        if customBridges != nil {
                            bridges = customBridges!
                        }
                    }

                    // wrap each bridge line in double-quotes (")
                    let quoted_bridges = bridges.map({ (bridge:String) -> String in
                        return "\"\(bridge)\""
                    })
                    for (_, bridge_arg) in quoted_bridges.enumerated() {
                        confs.append(["key":"bridge", "value":bridge_arg])
                    }

                    // Ensure we set UseBridges=1
                    torController.setConfForKey("usebridges", withValue: "1", completion: { (_, _) in
                    })

                    // Clear existing bridge conf and then set the new bridge configs.
                    torController.resetConf(forKey: "bridge", completion: { (_, _) in
                    })
                    torController.setConfs(confs, completion: { (_, _) in
                    })

                }

            }
        }

        // Wait long enough for tor itself to have started. It's OK to wait for this
        // because Tor is already trying to connect; this is just the part that polls for
        // progress.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
            if OnionManager.TOR_LOGGING {
                // Show Tor log in iOS' app log.
                TORInstallTorLogging()
                TORInstallEventLogging()
            }

            if !self.torController.isConnected {
                do {
                    try self.torController.connect()
                } catch {
                    print("Error info: \(error)")
                }
            }

            let cookieURL = OnionManager.torBaseConf.dataDirectory!.appendingPathComponent("control_auth_cookie")
            let cookie = try? Data(contentsOf: cookieURL)

            print("cookieURL: ", cookieURL as Any)
            print("cookie: ", cookie!)

            self.torController.authenticate(with: cookie!, completion: { (success, error) in
                if success {
                    var completeObs: Any?
                    completeObs = self.torController.addObserver(forCircuitEstablished: { (established) in
                        if established {
                            self.torHasConnected = true
                            self.torController.removeObserver(completeObs)
                            self.cancelFailGuard()
                            print("ESTABLISHED")
                            delegate?.torConnFinished()
                        }
                    }) // torController.addObserver

                    var progressObs: Any?
                    progressObs = self.torController.addObserver(forStatusEvents: {
                        (type: String, severity: String, action: String, arguments: [String : String]?) -> Bool in

                        if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                            let progress = Int(arguments!["PROGRESS"]!)!

                            delegate?.torConnProgress(progress)

                            if progress >= 100 {
                                self.torController.removeObserver(progressObs)
                            }

                            return true;
                        }

                        return false;
                    }) // torController.addObserver
                } // if success (authenticate)
                else { print("didn't connect to control port") }
            }) // controller authenticate
        }) //delay


        failGuard = DispatchWorkItem {
            if !self.torHasConnected {
                delegate?.torConnError()
            }
        }

        // Show error to user, when, after 30 seconds, Tor has still not started.
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: failGuard!)

    }// startTor

    private func bridgeLinesToArgs(_ bridgeLines: [String]) -> [String] {
        var bridges: [String] = []
        for (_, element) in bridgeLines.enumerated() {
            bridges.append("--bridge")
            bridges.append(element)
        }

        return bridges
    }

    /**
        Cancel the fail guard.
     */
    private func cancelFailGuard() {
        failGuard?.cancel()
        failGuard = nil
    }
}
