//
//  SpankBarApp.swift
//  SpankBar
//
//  Created by Scott on 23/03/2026.
//

import SwiftUI

  @main
  struct SpankBarApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          Settings { EmptyView() }
      }
  }
