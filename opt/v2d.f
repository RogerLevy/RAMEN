\ 2D vectors!  fixed point or integer either works
\ in experimental stage
\ future ideas:
\  - "V" registers with push and pop words.  all "vector" params implicit?

vocabulary v2d
only forth also v2d definitions
: 2!  swap over cell+ ! ! ;
: 2@  dup @ swap cell+ @ ;
: 2+!  swap over cell+ +! +! ;
only forth definitions also v2d
: vector  ( x y -- <name> )  create swap , , ;
2 cells constant /vector
: 2.  swap . . ;
: 3.  rot . 2. ;
: 2?  swap ? ? ;
: 3?  rot ? 2? ;
: v+  swap 2@ rot 2+! ;
: x@  @ ;
: y@  cell+ @ ;
: v*  >r  2@ r@ 2*  r> 2! ;
: v/  >r  2@ r@ 2/  r> 2! ;
: vmove  swap 2@ rot 2! ;
: vclamp  ( lowx lowy highx highy vec -- )  >r  2@ 2min 2max r> 2! ;
: 0v!  0 0 rot 2! ;
: 1v!  1 1 rot 2! ;
: 2rnd  ( x y -- x y )  rnd swap rnd swap ;
: vrnd  >r  2rnd  r> 2! ;
: uvec  ( deg -- x y )   >r  r@ cos  r> sin ;  \ get unit vector from angle
: vec  ( deg len -- x y )  >r  uvec  r> dup 2* ;
: angle  ( vec -- deg )  \ get angle of vector
    2@ 1f 1f fatan2 r>d f>p ;
: magnitude  ( vec -- n )  2@ 2f fdup f* fswap fdup f* f+ fsqrt f>p ;
: normalize  ( vec -- )  dup 2@ 2dup 0 0 d= ?exit  2dup magnitude dup 2/  ( 1 1 2+ ) rot 2! ;
: vdif  ( vec1 vec2 -- x y )  2@ rot 2@ 2- ;
: proximity  ( vec1 vec2 -- n ) vdif magnitude ;   \ distance between two vectors
: hypot  ( vec -- n )  2@ 1f fdup f* 1f fdup f* f+ fsqrt f>p ;
: dotp  ( vec1 vec2 - n ) swap 2@ rot 2@  -rot ( b.x a.y ) * >r  ( a.x b.y ) *  r> - ;
: rotate  ( deg vec -- )
    swap  dup cos  swap sin  locals| sin(ang) cos(ang) v |
    v x@ cos(ang) * v y@ sin(ang) * -
    v x@ sin(ang) * v y@ cos(ang) * +  v 2! ;
: scale  ( x y vec -- )
    >r  2@ 2*  r> 2! ;
: vlerp  ( vec1 vec2 n -- )
    locals| n v2 v1 |
    v1 x@ v2 x@ n lerp  v1 y@ v2 y@ n lerp  v2 2! ;
