# Network synchronisation

## Introduction

### Local Single Player

Creating a single player game with Godot is easy.

### Local Multiplayer

Creating a local multiplayer game with Godot is not much harder.

The only difference is that we have two viewport containers,
each one with its own viewports, but make the second viewport
point to the same world as the first viewport.

See this excerpt from `splitscreen.gd`:

    extends Node

    onready var viewports = [ 
        $VBoxContainer/ViewportContainer1/Viewport1,
        $VBoxContainer/ViewportContainer2/Viewport2,
    ]

    # Called when the node enters the scene tree for the first time.
    func _ready():
        
        # Make the second viewport point to the same world as the first one:
        viewports[1].world = viewports[0].world

Another point to keep in mind is that each player should use their own controller,
so we have to create unique names for the actions. This is easy as well.

### Network Multiplayer

Note: Network single player would be possible as well, but what for?

Before we go into details, let's just get one step further with...

### Network Multiplayer with splitscreen

This is only slightly more complicated than Network Multiplayer
with a single player per machine.

We have to keep in mind the difficulties for Network Multiplayer as such,
which will be discussed in the next section,
and in addition we need separate viewports and controllers for the local players
as described in the corresponding section above.

In addition to this natural sum of tricky points, there is one more thing
that seemed complicated at first:

The names of sibling nodes in a scene tree must be unique.
The documentation/tutorial recommends to use the `peer_id` as a suffix
for the avatars node names to uniquely identify players.
Unfortuantely, this cannot work if more than one player can play on the same peer.

As a solution, we might use the player's `global_id` instead.
But this is lengthy, which makes it unsuitable for network messages
and for debugging purposes.
Thus, we let the server create a shortened value
which is unique only for the duration of the network session.
We call this an `in_game_uid`.

## Discussion of Network Multiplayer

What makes network multiplayer complicated?

All players play in the same virtual world.
So they can see each others and interact with each other.
Interaction sadly means "shoot at each other" in most games, e.g PUBG or Fortnite.
If players A and B are on different peers, how can A notice what B does in the game?

At least, to see B, A has to know the position and facing direction of B, IOW B's transformation matrix.

If the players can interact with the world and with each other,
then player A also has to "see" or "know" what B does and how this changes
the environment.

So we have to exchange information about positions and actions/reactions over the network.

Note: Technically, we have to serialize/deserialize data, but that's another topic,
see the classes in the `network/message` directory. 

We can choose different approaches to this topic.

They differ in how compilcated they are to program, and how naturally they feel to the player.

## "Graphical terminal" approach

This is the easiest approach.

We consider each peer as a graphical terminal.
This means, that we just collect user input and send it to the server.
The server does most of the processing work, including physics.
The server then sends an update to our peer. This update is a description
of all the motions (or new positions/transformations) of all players,
possibly even of all relevant movable objects (eg. NPCs, bullets, moving rocks, ...).
The server will also send "actions" like what animation to play, what sound effect to start,
etc. to the client.
The client just receives a more or less long list of "commands" from the server which
it processes one by one.

This is OK for games where the network is very stable and for board games like chess
(well, probably except for bullet chess...) or for games where reaction time does not matter,
e.g. Anno xxxx games.

However, for action games, this approach probably does not work,
unless all the players are using a very fast and stable network.
I never actually tested this claim myself.

On the pro side, we can be sure that the experience is consistent for all players.

## More sophisticated approaches

More sophisticated approaches let the avatar react to the player's input actions
immediately. The information is still sent to the server, but the client does not
wait for the server's reply.

The server collects input/state messages from all clients,
*possibly validates it*,
and then sends this collected information to all clients.
So each client "sees" the other clients' avatars a bit in the past.

So each peer in fact has its own world. The worlds are very similar, but for example
if a bullet hits or misses a few inch makes a big difference in a shooter.

To avoid cheating, the server can validate and override the clients' messages.
The server is **authoritative**. 

For more details about how this can work in detail and what to keep in mind here,
see [Gaffer on Games](https://gafferongames.com/post/what_every_programmer_needs_to_know_about_game_networking/).

## Dealing with packet loss

Sometimes, a packet may get lost. The idea to compensate for this is to assume
that the input state is as before, such that e.g. a car continues to drive
in the same direction (or with the same steering angle) and that the pedals
are in the same position as before.
So the status can be predicted/extrapolated from the last known status.
This reduces "jumping" of avatars/bullets etc.

## Lag compensation

If, in a shooter, player A sees player B at position X and aims at B,
then in reality B has already moved away a bit from X.
The authoritative server decides if B was hit (to avoid cheating).
The server then has to "go back in time" the world a bit to see A's world as it
was at the time when A shot at B. It can therefore decide accurately
if the shot hit or missed.

AFAIK, this is the state of the art for Multiplayer network action games.

Of course, this is really complicated and requires significant processing power
on the server.



