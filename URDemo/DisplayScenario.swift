//
//  DisplayScenario.swift
//  URDemo
//
//  Created by Wolf McNally on 7/5/20.
//  Copyright © 2020 Arciem LLC. All rights reserved.
//

import SwiftUI
import URKit

protocol Preference { }

struct DisplayScenario: View {
    @ObservedObject var runningScenario: RunningScenario

    @Environment(\.horizontalSizeClass) var sizeClass

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(scenario: Scenario) {
        self.runningScenario = RunningScenario(scenario: scenario)
    }

    @State var columnWidth: CGFloat?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                HStack {
                    Text("length: \(runningScenario.messageLen)")
                    Text("maxFragment: \(runningScenario.maxFragmentLen)")
                    Text("parts: \(runningScenario.seqLen)")
                }
                .font(.caption)
                HStack {
                    Spacer()
                    Button(action: { self.runningScenario.restart() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
            VStack {
                URSummaryView(ur: $runningScenario.ur, lifeHashState: runningScenario.lifeHashState)
                QRCode(data: $runningScenario.part)
                    .frame(width: sizeClass == .regular ? 700 : 350)
                    .layoutPriority(1)
                    .background(GeometryReader {
                        Color.clear.preference(key: self.columnWidthKey, value: [$0.size.width])
                    })
                if !runningScenario.isSinglePart {
                    FragmentBar(views: $runningScenario.fragmentViews)
                    .background(GeometryReader {
                        Color.clear.preference(key: self.columnWidthKey, value: [$0.size.width])
                    })
                    Text("\(runningScenario.seqNum)").font(Font.system(.headline).bold().monospacedDigit())
                    HStack(spacing: 40) {
                        SpeedButton(imageName: "tortoise.fill") { self.runningScenario.slower() }
                        Text("\(runningScenario.framesPerSecond, specifier: "%.0f") fps").font(Font.system(.headline).bold().monospacedDigit())
                        SpeedButton(imageName: "hare.fill") { self.runningScenario.faster() }
                    }
                }
                Spacer()
            }
        }
        .frame(width: columnWidth)
        .padding()
        .navigationBarTitle(runningScenario.name)
        .onAppear {
            self.runningScenario.run()
        }
        .onDisappear {
            self.runningScenario.stop()
        }
        .onPreferenceChange(columnWidthKey) { prefs in
            let minPref = prefs.reduce(CGFloat.infinity, min)
            if minPref > 0 {
                self.columnWidth = minPref
            }
        }
    }

    struct AppendValue<T: Preference>: PreferenceKey {
        static var defaultValue: [CGFloat] { [] }
        static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
            value.append(contentsOf: nextValue())
        }
    }

    enum ColumnWidth: Preference { }
    let columnWidthKey = AppendValue<ColumnWidth>.self
}

struct DisplayScenario_Previews: PreviewProvider {
    static let scenario = Scenario(name: "A", messageLen: 1024, maxFragmentLen: 100)

    static var previews: some View {
        NavigationView {
            DisplayScenario(scenario: Self.scenario)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .darkMode()
    }
}

struct SpeedButton: View {
    let imageName: String
    let action: () -> Void

    init(imageName: String, action: @escaping () -> Void) {
        self.action = action
        self.imageName = imageName
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: 32)
    }
}
