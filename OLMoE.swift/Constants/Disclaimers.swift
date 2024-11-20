//
//  Untitled.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/14/24.
//

import Foundation

protocol Disclaimer {
    var title: String { get }
    var text: String { get }
    var buttonText: String { get }
}

struct Disclaimers {
    struct MainDisclaimer: Disclaimer {
        let title = "[TODO] Disclaimers"
        let text = """
       Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam odio urna, porta vel eleifend volutpat, porta vitae justo. Aenean sit amet sem id urna consectetur feugiat. Morbi in sem gravida orci rutrum maximus. Donec pretium accumsan orci quis elementum. Sed a tempor libero. Cras tempus nisl ut mattis pretium. Fusce in congue arcu. Vivamus nec sollicitudin est. Cras id eleifend nisl. Phasellus quis neque in leo accumsan fermentum et quis diam. Integer non lectus blandit, hendrerit ante sed, bibendum sapien. Etiam quis facilisis ante. Donec lacinia tincidunt est, quis volutpat est tincidunt et. Nullam nibh risus, tempor quis lacinia ac, dictum et arcu. Curabitur sit amet mauris id mi facilisis laoreet a non metus.
       """
        let buttonText = "Next \u{02192}"
   }
   
   struct AdditionalDisclaimer: Disclaimer {
        let title = "[TODO] Additional Disclaimers"
        let text = """
       Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam odio urna, porta vel eleifend volutpat, porta vitae justo. Aenean sit amet sem id urna consectetur feugiat. Morbi in sem gravida orci rutrum maximus. Donec pretium accumsan orci quis elementum. Sed a tempor libero. Cras tempus nisl ut mattis pretium. Fusce in congue arcu. Vivamus nec sollicitudin est. Cras id eleifend nisl. Phasellus quis neque in leo accumsan fermentum et quis diam. Integer non lectus blandit, hendrerit ante sed, bibendum sapien. Etiam quis facilisis ante. Donec lacinia tincidunt est, quis volutpat est tincidunt et. Nullam nibh risus, tempor quis lacinia ac, dictum et arcu. Curabitur sit amet mauris id mi facilisis laoreet a non metus.
       """
        let buttonText = "I Agree"
   }
    
    struct ShareDisclaimer: Disclaimer {
        let title = "[TODO] Share Disclaimers"
        let text = "The Ai2 Playground is intended for research and educational purposes in accordance with our Terms of Use, Responsible Use Guidelines, and Privacy Policy. The Ai2 Playground collects user queries and inputs entered into it as well as other information about the user. You will have 30 days to delete your queries will be stored and used for future research and educational purposes in the public interest consistent with Ai2’s mission as a 501(c)(3) nonprofit organization. All retained prompt history and user interaction data shared with the Ai2 Playground and Dataset Explorer may be shared outside of Ai2, as permitted by applicable law and Ai2’s policies. Please use your discretion and best judgment when accessing and Playground. NEVER submit any personal, sensitive, or confidential your use of the Ai2 Playground or Dataset Explorer."
        let buttonText = "Share"
    }
}
