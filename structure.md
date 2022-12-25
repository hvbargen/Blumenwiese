# Program structure

## Network synchronization

See [separate page](network_sync.md)

## Directory structure

### Splitscreen.*

The Splitscreen scene `SplitScreen.tscn` and its corresponding script
was originally constructed to see how local splitscreen games work in Godot.

ATM it is also used when one or two players play locally or in a network game.
In case of only one player, the second viewport container is simply removed.

TODO: We could create a split-screen for up to 4 players, as in Mario Kart.

### scenes

For each scene, there is a separate folder here.
Scripts that clearly belong to the scene are stored there as well.

### network

### network/messages

What I consider a bit of a weakness in Godot is marshalling,
that is serializing and deserializing of data structures,
or the absence of "data classes" or "data transfer objects" (DTOs).

Note that I say "data structures", not "objects".
Deserializing objects is a security issue.
Godot allows Serializing/Deserisaling objects, but prevents it by default.

What works out of the box is deserializng of the basic data types
and basic structures `Array` and `Dictionary`.

But then again, using these for variables doesn't give you the warm feeling
of type safety in comparison to classes.

#### Message base class

As a compromise, I chose a base class `Message` for all messages that
are to be transferred over the network.

It expects a function which returns an Array of names
of the properties that are to be transferred.
The function `to_array` will then create an array of those property values.

All DTOs have to be classes derived from `Message` and provide the function `get_properties`.When send
The result of the `to_array` function can then be used for arguments in `rpc` calls.
On the receiver side, the constructor function can be used to reconstruct the DTO. 

### scenes/blumenwiese

This is the "in game world" or level scene.
ATM the scene is very reduced to the absolutely necessary:
A ground and a skybox.

A avatars can around on the ground and jump.
When an avatar jumps, it throws (spawns) a seed,
which will eventually become a flower.

The directory also contains some other helper scenes for seeds, flowers etc
which are used internally in the `Main.tscn`.

For the leafs and the blossom, we are using shaders 
(just because I wanted to learn shader programming).
 
### scenes/podest

The purpose of this scene is mainly to show an avatar
in the lobby. The avatar can jump and run, but it can't run away :-)

## Nomenclature

### Acronyms

The following acronyms are used frequently:

`uid`:
    unique identifier (note: in other contexts, it could mean user identifier)

`vpc`:
    Used as a variable name prefix for `ViewportContainer`

`vp`:
    Used as a variable name prefix for `Viewport`

`scn`:
    Scene

`DTO`:
    Data Transfer Object

### Data Transfer Object

A Data Transfer Object, or DTO for short, is an object without any logic.
Its only purpose is to be used as the content of a message, or as the result of a message.
In particular, this is useful if the message has to be serialized, e.g. for inter-process-communication.

### Avatar

An avatar is a virtual "person" (more or less human) which is usually
controlled by a human player with a controller (e.g. a gamepad).

### Gardener

In this particular game, the avatars are shaped like the Godot
mascot robot.
They are called "gardeners" because they can throw seeds which,
when the touch the ground, will sink and then spawn a flower.
Remark: The "game" has no objective at the moment.

### PlayerProfile

A `PlayerProfile` is comparable to something like a Mii on Nintendo.
The intention is to describe properties of a human player which are
**independent from a particular game**.

A human player can of course have several player profiles.

Player profiles are usually stored locally on a machine.
Later it may be possible to store a player profile on a central,
common server in the internet.
This would allow storing achievements, high scores etc.

Important properties are:

 - A `nickname` for the player, which doesn't need to be unique.
 - Favorite colors: `fav_color1` and `fav_color2`.
   These can be used by games to make the avatar recognizable.

Later maybe:

 - Language and region.
 - Left-handed or right-handed?
 - Configurable action bindings for different input devices,
   e.g. for a keyboard, if using WASD or cursor keys form movement.
 - Visual properties (e.g. how does the avatar look in games if the
   game wants to use this information - similar to Nintendo Mii).
 - User preferences for font sizes, contrast, TTS, subtitles, ...)
 - An owner. This would be an account id for a registered human person.
   The intention is that only the owner can change some of the properties
   of the `PlayerProfile`. 

### Global ID

A `global_id` is a globally (world-wide) unique ID identifying a player profile.
This is a (quite long) text string.

We don't use a separate type for this, the meaning is clear from the variable name.

ATM the value is computed from the machine's unique id and a timestamp.
So in theory, it should be globally unique.

### In-Game Unique ID

An `in_game_uid` is a temporay ID which is unique inside a network session.
It is the responsibility of the server to assign a unique `in_game_uid` to
each of the `PlayerProfile`s (or to their corresponding `global_id`s).
The `in_game_uid` is used mainly because it is much shorter than the `global_id`.
So it is more suited for naming `Node`s and `Scene`s in the game and for
sending information over the network.

### Network peer and peer_id

In a network game, each machine (or each process, if we run two instances
of the game on the same machine accidentally) has a unique `peer_id`, which
is an integer number.

The server has the peer_id = 1.
The clients have peer_id values > 1.
Values <= 0 are invalid.
We can use the `peer_id` = -1 to indicate a local game, in places where
a `peer_id` value must be supplied.

We can use Godot's functions to detect if there is a network peer
(e.g. we are a server or a client, whether connected or not) or not.
And if we are in a network, we can find out our own `peer_id`, and
in case of remote function call the sender's `peer_id`.

### Deprecated

NetworkPlayer: Replaced with PlayerProfile

#### Deprecated acronyms

nw_player = NetworkPlayer instance
