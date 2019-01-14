[defined] object-maxsize not [if] 256 cells constant object-maxsize [then] 
object-maxsize constant maxsize
[defined] roledef-size [if] roledef-size [else] 4 kb [then] constant /roledef

variable lastrole \ used by map loaders (when loading objects scripts)
struct %role
struct %object
%object value fields  \ change this to create unrelated object-y structs (careful!)
create basis /roledef /allot  \ default rolevar and action values for all newly created roles

\ ME is defined in afkit
: as ( object - ) s" to me" evaluate ; immediate
create mestk  0 , 16 cells allot
: i{ ( - ) me mestk dup @ cells + cell+ !  mestk @ 1 + 15 and mestk ! ;  \ interpretive version, uses a sw stack
: i} ( - ) mestk @ 1 - 15 and mestk !  mestk dup @ cells + cell+ @ to me ; 
: {  ( - ) state @ if s" me >r" evaluate else  i{  then ; immediate
: }  ( - ) state @ if s" r> as" evaluate else  i}  then ; immediate
: >{ ( object - )  s" { as " evaluate ; immediate    \ }

: (used)  ( - adr ) %object struct.size ;

variable redef  \ should you want to bury anything
redef on  \ we'll keep this on while compiling RAMEN itself

: >magic  ( adr - n ) %field @ + @ ;
: ?unique  ( size - size | <cancel caller> )
    redef @ ?exit
    >in @
        bl word find  if
            >body dup >r >magic $76543210 =  if
                r> to lastfield
                r> drop  ( value of >IN ) drop  ( size ) drop  exit
            else
                r> ( body ) drop
            then
        else
            ( addr ) drop
        then
    >in ! ;

: ?maxsize  ( - ) (used) @ maxsize >= abort" Cannot create object field; USED is maxed out. Increase OBJECT-MAXSIZE." ;
: field ( size - <name> )  ?unique ?maxsize fields swap create-field $76543210 , does> field.offset @ me + ;
: var ( - <name> ) cell field ;
: 's  ( object - <field> adr ) ' >body field.offset @ ?lit s" +" evaluate ; immediate  \ also works with rolevars

\ objects are organized into objlists, which are forward-linked lists of objects
\  you can continually add (statically allocate and link) objects to these lists
\  you can create "pools" which can dynamically allocate objects
\  you can itterate over objlists as a whole, or just over a pool at a time

%node @ %object struct.size +!
var id  \ don't move this (?)
(used) @ constant /objhead
var en <hex  var hidden <flag  
var x  var y  var vx  var vy
var drw <adr  var beha <adr
var marked <flag \ for deletion
variable nextid

: object,  ( - ) maxsize allotment /node ;

create defaults  object,                \ default values are stored here
                                        \ they are copied to new instances by INIT
defaults as  en on 

create pool  object,                    \ where we cache free objects
create root  object,                    \ parent of all objlists

: >first  ( node - node|0 ) node.first @ ;
: >last   ( node - node|0 ) node.last @ ;
: >parent  ( node - node|0 ) node.parent @ ;
: !id  1 nextid +!  nextid @ id ! ;
: init  ( - ) defaults 's en en [ maxsize /objhead - ]# move  !id ;
: one ( parent - me=obj ) new-node as init me swap push at@ x 2! ;
: objects  ( parent n - ) for dup one loop drop ;
: ?remove  ( obj - ) dup >parent dup if remove else drop drop then ;
:noname  pool length 0= if here object, else pool pop then ; is new-node
:noname  >{ en @ $fffffffe <> if me pool push else me ?remove then } ; is free-node
: dismiss ( - ) marked on ;
: dynamic?  ( - flag ) en @ #1 and ;

\ making stuff move and displaying them
: ?call  ( adr - ) ?dup -exit call ;
: draw   ( - ) en @ -exit  hidden @ ?exit  x 2@ at  drw @ ?call ;
: draws  ( objlist ) each> as draw ;
: act   ( - ) en @ -exit  beha @ ?call ;
: sweep ( objlist ) each> as marked @ -exit marked off id off me free-node ;
: acts  ( objlist ) each> as act ;
: draw>  ( - <code> ) r> drw ! hidden off ;
: act>   ( - <code> ) r> beha ! ;
: away  ( obj x y - ) rot 's x 2@ 2+ at ;
: -act  ( - ) act> noop ;
: objlist  ( - <name> )  create here as object, init me root push ;

\ stage
objlist stage  \ default object list
: /pool   pool %node venery-sizeof erase  pool /node ;
: /stage  stage vacate  /pool  0 nextid ! ;

\ static objects
: object   ( - ) here as object, me stage push init $fffffffe en ! ;

\ Roles
\ Note that role vars are global and not tied to any specific role.
\ also, note that DERIVE defaults all actions to call the BASIS's current definition
\ indirectly, so it can be changed anytime.
var role <adr
basis defaults 's role !
: ?update  ( - <name> )  >in @  defined if  >body lastrole !  drop r> drop exit then  drop >in ! ;

: role@  ( - role ) role @ dup 0= abort" Error: Role is null." ;
: create-rolefield  ( size - <name> ) %role swap create-field $76543210 , 0 , ;
: rolefield  ( size - <name> ) ?unique create-rolefield  does> field.offset @ role@ + ;
: rolevar  ( - <name> ) 0 ?unique drop  cell create-rolefield  does> field.offset @ role@ + ;
: is-action?  %field @ + cell+ @ ;
: ?execute  dup if execute ;then drop ;
: action   ( - <name> ) ( ??? - ??? )
    0 ?unique drop  cell create-rolefield  true here cell- ! <adr
    does> field.offset @ role@ + @ ?execute ;
: :to   ( roledef - <name> ... )  ' >body field.offset @ + :noname swap ! ;
: +exec  + @ execute ;
: ->  ( roledef - <action> )
    ' >body field.offset @ postpone literal postpone +exec ; immediate

:slang .name    body> >name count type space ;
:slang relate
    here locals| child |
    basis /roledef move,
    ['] is-action? %role some>
        :noname swap
        field.offset @ 
        dup basis + postpone literal s" @ ?execute ; " evaluate  \ compile "bridge"
        child + !  \ assign our "bridge" to the corresponding action
;
: defrole  ( - <name> ) ?update  create  here lastrole !  relate ;



\ Inspection
: o.   ( obj - ) dup h. %object .fields ;
: .me  ( - ) me o. ;
: .role  ( obj - )  's role @ ?dup if %role .fields else ." No role" then ;
: .objlist  ( objlist - )  dup length . each> as  cr ." ID: " id ?  ."  X/Y: " x 2? ;