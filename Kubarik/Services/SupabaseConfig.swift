//
//  SupabaseConfig.swift
//  Kubarik
//
//  Public surface for Supabase project URL + anon key. The actual values
//  live in `SupabaseConfig-local.swift` (gitignored). To run this project
//  against your own Supabase instance:
//
//    1. Copy `SupabaseConfig-local.example.swift` to `SupabaseConfig-local.swift`
//    2. Fill in your project URL and anon key
//    3. Make sure the file is added to the Kubarik build target in Xcode
//
//  The anon key is intentionally client-facing — RLS policies on the
//  database enforce access control. Never ship the service_role key.
//

import Foundation

enum SupabaseConfig {
    static let projectURL = URL(string: SupabaseConfigLocal.projectURLString)!
    static let anonKey = SupabaseConfigLocal.anonKey
}
