use aztec::macros::aztec;

#[aztec]
pub contract ProfileSharing {

    use aztec::{
        messages::logs::note::encode_and_encrypt_note,
        state_vars::{private_set::PrivateSet, map::Map},
        note::note_viewer_options::NoteViewerOptions,
        note::constants::MAX_NOTES_PER_PAGE,
        macros::{
            functions::{initializer, private, utility, public},
            storage::storage,
            notes::note,
        },
        protocol_types::{
            address::AztecAddress, 
            traits::{Packable, Serialize}
        }
    };

    #[derive(Eq,Serialize,Packable)]
    #[note]
    pub struct ProfileNote {
        name_hash: Field,
        bio_hash: Field,
        age: u8,
        owner: AztecAddress,
        randomness: Field,
    }

    #[storage]
    struct Storage<Context> {
        profiles: Map<AztecAddress, PrivateSet<ProfileNote, Context>, Context>,
    }

    // Constructor - no initialization needed for simple profile sharing
    #[initializer]
    #[public]
    fn constructor() {
        // No initialization needed
    }

    // Create or update a profile
    #[private]
    fn create_profile(
        name_hash: Field,
        bio_hash: Field,
        age: u8,
        randomness: Field
    ) {
        let owner = context.msg_sender();
        
        // Create a new profile note
        let profile_note = ProfileNote {
            name_hash,
            bio_hash,
            age,
            owner,
            randomness,
        };
        
        // Insert the note into the user's profile set
        storage.profiles.at(owner).insert(profile_note).emit(encode_and_encrypt_note(&mut context, context.msg_sender()));
    }

    // Share a profile with another user
    #[private]
    fn share_profile(
        recipient: AztecAddress,
        name_hash: Field,
        bio_hash: Field,
        age: u8,
        randomness: Field
    ) {
        // Create a new profile note with recipient as owner
        let shared_profile = ProfileNote {
            name_hash,
            bio_hash,
            age,
            owner: recipient, // Recipient becomes the owner
            randomness,
        };
        
        // Insert the note into the recipient's profile set
        storage.profiles.at(recipient).insert(shared_profile).emit(encode_and_encrypt_note(&mut context, context.msg_sender()));
    }

    // Update an existing profile (nullify old, create new)
    // #[private]
    // fn update_profile(
    //     old_note: ProfileNote,
    //     new_name: [u8; 32],
    //     new_bio: [u8; 128],
    //     new_age: u8,
    //     new_randomness: Field
    // ) {
    //     let owner = context.msg_sender();
        
    //     // Verify ownership of the old note
    //     assert(old_note.owner == owner, "Not the owner of this profile");
        
    //     // Remove the old note (nullify it)
    //     storage.profiles.at(owner).remove(old_note);
        
    //     // Create and insert the new profile note
    //     let updated_profile = ProfileNote {
    //         name: new_name,
    //         bio: new_bio,
    //         age: new_age,
    //         owner,
    //         randomness: new_randomness,
    //     };
        
    //     storage.profiles.at(owner).insert(updated_profile);
    // }

    // Utility function to view profiles (as described in PRD)
    #[utility]
    unconstrained fn view_profiles(owner: AztecAddress) -> BoundedVec<ProfileNote, MAX_NOTES_PER_PAGE> {
        storage.profiles.at(owner).view_notes(NoteViewerOptions::new())
    }

    // Utility function to get a specific profile by owner
    // Returns (found, note). If not found, note contains zero fields.
    #[utility]
    unconstrained fn get_profile(owner: AztecAddress) -> (bool, ProfileNote) {
        let notes = storage.profiles.at(owner).view_notes(NoteViewerOptions::new());
        if notes.len() > 0 {
            (true, notes.get_unchecked(0))
        } else {
            let empty = ProfileNote { name_hash: 0, bio_hash: 0, age: 0, owner, randomness: 0 };
            (false, empty)
        }
    }
}