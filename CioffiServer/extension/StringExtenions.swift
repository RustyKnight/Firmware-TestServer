//
// Created by Shane Whitehead on 2/2/17.
// Copyright (c) 2017 Beam Communications. All rights reserved.
//

import Foundation

public extension String {
	/// Trims the string of all white space and new line characters
	public var trim: String {
		return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}

	public var isEmptyWhenTrimmed: Bool {
		return trim.characters.count == 0
	}
}