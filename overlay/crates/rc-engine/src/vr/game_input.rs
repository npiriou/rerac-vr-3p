//! Headset session focus is tracked independently of gameplay input.
use bevy::prelude::*;
use bevy_mod_openxr::poll_events::{OxrEventHandlerExt, OxrEventIn};
use bevy_mod_xr::session::XrPreDestroySession;

#[derive(Resource, Default)]
pub(super) struct Focused(pub bool);

pub struct HeadsetFocusPlugin;

impl Plugin for HeadsetFocusPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<Focused>()
            .add_oxr_event_handler(focus_event)
            .add_systems(XrPreDestroySession, clear_focus);
    }
}

fn clear_focus(mut focus: ResMut<Focused>) {
    focus.0 = false;
}

fn focus_event(event: OxrEventIn, mut focus: ResMut<Focused>) {
    if let openxr::Event::SessionStateChanged(state) = *event {
        focus.0 = state.state() == openxr::SessionState::FOCUSED;
        println!("VR_GAME headset_focus={}", focus.0);
    }
}
