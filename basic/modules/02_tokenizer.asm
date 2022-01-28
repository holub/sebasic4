;	// SE Basic IV 4.2 Cordelia
;	// Copyright (c) 1999-2022 Source Solutions, Inc.

;	// SE Basic IV is free software: you can redistribute it and/or modify
;	// it under the terms of the GNU General Public License as published by
;	// the Free Software Foundation, either version 3 of the License, or
;	// (at your option) any later version.
;	// 
;	// SE Basic IV is distributed in the hope that it will be useful,
;	// but WITHOUT ANY WARRANTY; without even the implied warranty o;
;	// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;	// GNU General Public License for more details.
;	// 
;	// You should have received a copy of the GNU General Public License
;	// along with SE Basic IV. If not, see <http://www.gnu.org/licenses/>.

;;
;	// --- TOKENIZER -----------------------------------------------------------
;;

;;
; tokenizer
;;
tokenizer:
	res 7, (iy + _flags);				// force edit mode
	set 7, (iy + _err_nr);				// set no error
	call editor;						// prepare line
	call var_end_hl;					// varaibles end marker location to HL

tokenizer_0:
	xor a;								// first pass
	ld de, tk_ptr_rem;					// check REM first

tokenizer_1:
	ld hl, (e_line);					// fetch line start
	push de;							// store token
	pop ix;								// position in IX

tokenizer_2:
	ld bc, 0;							// clear alpha flag
	push af;							// stack token number

tokenizer_3:
	push ix;							// restore token
	pop de;								// position to DE

tokenizer_4:
	ld a, (hl);							// get character

	bit 0, c;							// in quotes?
	jp nz, in_q;						// jump if so

;colon_else:
;	cp ' ';								// is it space?
;	jr nz, sbst_eq;						// jump if not
;
;	dec hl;								// previous character
;	ld a, (hl);							// get it
;	cp ':';								// colon?
;	inc hl;								// current character
;	ld a, (hl);							// restore it
;	jr z, sbst_eq;						// jump if there is already a colon
;
;	ld (mem_5_1), hl;					// store position
;	inc hl;								//
;	ld a, (hl);							//
;	or %00100000;						// make lowercase
;	cp 'e';								// is it E;
;	jr nz, not_else;					// jump if not
;	inc hl;								//
;	ld a, (hl);							//
;	or %00100000;						// make lowercase
;	cp 'l';								// is it E;
;	jr nz, not_else;					// jump if not
;	inc hl;								//
;	ld a, (hl);							//
;	or %00100000;						// make lowercase
;	cp 's';								// is it E;
;	jr nz, not_else;					// jump if not
;	inc hl;								//
;	ld a, (hl);							//
;	or %00100000;						// make lowercase
;	cp 'e';								// is it E;
;	jr nz, not_else;					// jump if not
;	ld hl, (mem_5_1);					// restore position
;	ld (hl), ':';						// insert colon
;	inc hl;								// next character
;	jr tokenizer_4;						// immediate jump
;
;not_else:
;	ld hl, (mem_5_1);					// restore position
;	ld a, (hl);							// restore character

sbst_eq:
	cp '=';								// test for equals
	jr nz, sbst_neql;					// jump if not
	inc hl;								// advance one character
	ld a, '<';							// less than
	cp (hl);							// test for it
	jr z, sbst_sym_eq;					// jump if so;
	ld a, '>';							// greater than
	cp (hl);							// test for it
	jr z, sbst_sym_eq;					// jump if so;
	dec hl;								// restore pointer
	ld a, (hl);							// restore value
	jr sbst_neql;						// jump for next test

sbst_sym_eq:
	ld (hl), '=';						// swap
	dec hl;								// symbols
	jr do_sbst;							// do substitution

sbst_neql:
	cp '>';								// test for greater than
	jr nz, sbst_lookup;					// jump if not
	inc hl;								// advance one character
	ld a, '<';							// less than
	cp (hl);							// test for it
	jr z, sbst_gt;						// jump if so
	dec hl;								// restore pointer
	ld a, (hl);							// restore value
	jr sbst_lookup;					// jump for next test

sbst_gt:
	ld (hl), '>';						// greater than
	dec hl;								// back one character
	jr do_sbst;							// do substitution

sbst_lookup:
	ld (mem_5_1), hl;					// store position
	ld b, a;							// store code point
	ld hl, sbst_chr_tbl;				// address table

sbst_lk_loop:
	ld a, (hl);							// code in table
	and a;								// null terminator?
	jr z, sbst_not_found;				// jump if so
	inc hl;								// advance
	inc hl;								// pointer
	cp b;								// match?
	jr nz, sbst_lk_loop;				// loop until done
	dec hl;								// back one position
	ld a, (hl);							// get substitute value;
	ld hl, (mem_5_1);					// restore HL
	ld (hl), a;							// substitute value
	inc hl;								// next character
	jp tokenizer_4;						// immediate jump

sbst_not_found:
	ld hl, (mem_5_1);					// restore HL
	ld a, (hl);							// restore character

do_sbst:
	ld (hl), a;							// write character back (for subs)

in_q:
	cp "'";								// substitute REM token?
	jr z, tokenizer_14;					// jump if so
	cp tk_rem;							// REM token?
	jr z, tokenizer_14;					// jump if so
	cp ctrl_cr;							// carraige return?
	jr z, tokenizer_14;					// jump if so
	cp $22;								// in quotes?
	jr nz, tokenizer_5;					// jump if not
	inc c;								// toggle bit 0

tokenizer_5:
	bit 0, c;							// in quotes?
	jr nz, tokenizer_7;					// jump if so
	call tokenizer_17;					// alpha?
	jr nc, tokenizer_6;					// jump if not
	bit 7, b;							// was previous alpha?
	jr nz, tokenizer_7;					// jump if so

tokenizer_6:
	ex de, hl;							// switch HL and DE
	cp (hl);							// first character match?
	ex de, hl;							// switch back
	jr z, tokenizer_8;					// jump if match

tokenizer_7:
	inc hl;								// next character
	jp tokenizer_4;						// repeat until end of line

tokenizer_8:
	ld (mem_5_1), hl;					// store position

tokenizer_9:
	inc hl;								// next position
	ld a, (hl);							// character to A
	call tokenizer_17;					// make caps
	ex af, af';							// store A

tokenizer_10:
	ex af, af';							// restore A
	inc de;								// next character of token
	ex de, hl;							// switch HL and DE
	cp (hl);							// does next character match?
	ex de, hl;							// switch back
	jr z, tokenizer_9;					// jump if match
	ex af, af';							// store A
	ld a, (de);							// token character to A
	cp ' ';								// space?
	jr z, tokenizer_10;					// jump if so
	ex af, af';							// restore A
	cp '.';								// abbreviation?
	jr z, tokenizer_11;					// jump if so
	or %10000000;						// set bit 7
	ex de, hl;							// token character address to HL
	cp (hl);							// final character?
	ex de, hl;							// token character address to DE
	jp nz, tokenizer_3;					// start at next with no match
	cp 128 + '@';						// non-alpha?
	jr c, tokenizer_12;					// jump if so

tokenizer_11:
	inc hl;								// next character
	ld a, (hl);							// trailing character to A
	cp ' ';								// space?
	jr z, tokenizer_12;					// jump if so
	dec hl;								// final character of token
	cp '$';								// string?
	jp z, tokenizer_3;					// jump if so
	call alpha;	'|'						// alpha?
	jp c, tokenizer_3;					// jump if so

tokenizer_12:
	ld de, (mem_5_1);					// first character

tokenizer_13:
	dec de;								// point to leading character
	ld a, (de);							// store it in A
	cp ' ';								// space?
	jr z, tokenizer_13;					// jump if so
	inc de;								// first character
	call reclaim_1;						// remove spaces
	pop af;								// unstack token
	push ix;							// store IX
	pop de;								// in DE
	push af;							// stack A
;	add a, 6;							// add offset (used with 0-5)
	ld (hl), a;							// insert token
	pop af;								// unstack A
	and a;								// REM?
	jp nz, tokenizer_2;					// jump if not
	ld (hl), tk_rem;					// store REM token
	push af;							// prevent loop

tokenizer_14:
	ld de, tk_ptr_last;					// start of final token
	pop af;								// restore token
	sub 1;								// dec A and set carry if zero
	jp c, tokenizer_1;					// jump if carry flag set.
	cp first_tk - 1; 					// first token?
;	cp first_tk - 7; 					// first token? (used with 0-5)
	ret z;								// return if so
	push ix;							// IX to
	pop hl;								// HL

tokenizer_15:
	dec hl;								// end of previous token

tokenizer_16:
	dec hl;								// down one character
	bit 7, (hl);						// final character of a token?
	jr z, tokenizer_16;					// jump if not
	inc hl;								// first character of next token
	ex de, hl;							// store in DE
	jp tokenizer_1;						// next token

tokenizer_17:
;	bit 3, (iy + _flags2);				// don't tokenize lower case if caps in use 
;	ret nz;								// enables use of reserved words as variable names
	call alpha;							// test alpha
	ld b, c;							// previous result to B
	ld c, 0;							// clear C
	ret nc;								// return if non-alpha
	res 5,a;							// make upper case
	set 7, c;							// set flag if alpha
	ret;								// end of subroutine
