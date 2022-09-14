//
//  Copyright 2022 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public class LocalTestsConstants: NSObject {
    
    /**
     This float ranges from 0 to 1 and will be used to calculate how precise a snapshot test will be,
     where 1 means all pixels should match, and 0 means that none of them need to match.
     */
    static public let testPrecision: CGFloat = 0.9
    
    /**
     In these local tests, we will use test precision to calculate pixel tolerance.
     */
    static public var perPixelTolerance: CGFloat {
        return 1.0 - testPrecision
    }
    
    /**
     Used to activate or deactivate record mode. If active, new snapshots will be recorded/saved for
     those thats that are run.
     */
    static public let isRecordMode: Bool = false
    
}
