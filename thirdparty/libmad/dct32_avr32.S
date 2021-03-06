/*
   Optimized 32-point Discrete Cosine Transform (DCT)
   Copyright 2003-2006 Microchip Technology Inc.

   Written by Ronny Pedersen, Atmel Norway

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

#define	SHIFT	12
#define MAD_F_SCALEBITS 28
#define SLOTS 8

#define MAD_F(x)	((x + (1 << 15)) >> 16)

#  define costab1	MAD_F(0x7fd8878e)
#  define costab2	MAD_F(0x7f62368f)
#  define costab3	MAD_F(0x7e9d55fc)
#  define costab4	MAD_F(0x7d8a5f40)
#  define costab5	MAD_F(0x7c29fbee)
#  define costab6	MAD_F(0x7a7d055b)
#  define costab7	MAD_F(0x78848414)
#  define costab8	MAD_F(0x7641af3d)
#  define costab9	MAD_F(0x73b5ebd1)
#  define costab10	MAD_F(0x70e2cbc6)
#  define costab11	MAD_F(0x6dca0d14)
#  define costab12	MAD_F(0x6a6d98a4)
#  define costab13	MAD_F(0x66cf8120)
#  define costab14	MAD_F(0x62f201ac)
#  define costab15	MAD_F(0x5ed77c8a)
#  define costab16	MAD_F(0x5a82799a)
#  define costab17	MAD_F(0x55f5a4d2)
#  define costab18	MAD_F(0x5133cc94)
#  define costab19	MAD_F(0x4c3fdff4)
#  define costab20	MAD_F(0x471cece7)
#  define costab21	MAD_F(0x41ce1e65)
#  define costab22	MAD_F(0x3c56ba70)
#  define costab23	MAD_F(0x36ba2014)
#  define costab24	MAD_F(0x30fbc54d)
#  define costab25	MAD_F(0x2b1f34eb)
#  define costab26	MAD_F(0x25280c5e)
#  define costab27	MAD_F(0x1f19f97b)
#  define costab28	MAD_F(0x18f8b83c)
#  define costab29	MAD_F(0x12c8106f)
#  define costab30	MAD_F(0x0c8bd35e)
#  define costab31	MAD_F(0x0647d97c)


	.macro	butterfly2_in out1, out2, out3, out4, in, idx_in1, idx_in2, idx_in3, idx_in4, coeff1, coeff2, tmplo, tmphi
	mov	\tmplo, \coeff1
	ld.w	\out1, \in[\idx_in1 * 4]
	ld.w	\out2, \in[\idx_in2 * 4]
	ld.w	\out3, \in[\idx_in3 * 4]
	ld.w	\out4, \in[\idx_in4 * 4]
	sub	\tmphi, \out1, \out2
	add	\out1, \out2
	mulsatrndwh.w	\out2, \tmphi, \tmplo:b

	sub	\tmphi, \out3, \out4
	mov	\tmplo, \coeff2
	add	\out3, \out4
	mulsatrndwh.w	\out4, \tmphi, \tmplo:b
	.endm

	.macro	butterfly2	in1, in2, in3, in4, coeff1, tmplo, tmphi, tmp
	mov	\tmp, \coeff1
	sub	\tmphi, \in1, \in2
	add	\in1, \in2
	mulsatrndwh.w	\in2, \tmphi, \tmp:b

	sub	\tmphi, \in3, \in4
	add	\in3, \in4
	mulsatrndwh.w	\in4, \tmphi, \tmp:b
	.endm

	.macro	butterfly4	in1, in2, in3, in4, in5, in6, in7, in8, coeff1, tmplo, tmphi, tmp
	mov	\tmp, \coeff1
	sub	\tmphi, \in1, \in2
	add	\in1, \in2
	mulsatrndwh.w	\in2, \tmphi, \tmp:b

	sub	\tmphi, \in3, \in4
	add	\in3, \in4
	mulsatrndwh.w	\in4, \tmphi, \tmp:b

	sub	\tmphi, \in5, \in6
	add	\in5, \in6
	mulsatrndwh.w	\in6, \tmphi, \tmp:b

	sub	\tmphi, \in7, \in8
	add	\in7, \in8
	mulsatrndwh.w	\in8, \tmphi, \tmp:b
	.endm

	.macro	scale	reg
	.endm

  .section  .text.dct32_avr32, "ax", @progbits

  .align  2

/*void dct32(	mad_fixed_t const in[32], unsigned int slot,
		mad_fixed_t lo[16][8], mad_fixed_t hi[16][8]) */

	.global	dct32_avr32
dct32_avr32:
	stm	--sp, r0-r7, r9-r11, lr

	sub	sp, 32*4

/*	t0   = in[0]  + in[31];  t16  = MUL(in[0]  - in[31], costab1);
	t1   = in[15] + in[16];  t17  = MUL(in[15] - in[16], costab31); */
	butterfly2_in	r4/*t0*/, r5/*t16*/, r6/*t1*/, r7/*t17*/, r12, 0, 31, 15, 16, costab1, costab31, r10, r11

/*	t41  = t16 + t17;
	t59  = MUL(t16 - t17, costab2);
	t33  =	 t0  + t1;
	t50  = MUL(t0  - t1,  costab2);*/
	butterfly2	r5/*t41*/, r7/*t59*/, r4/*t33*/, r6/*t50*/, costab2, r10, r11, lr

/*	t2   = in[7]  + in[24];  t18  = MUL(in[7]  - in[24], costab15);
	t3   = in[8]  + in[23];  t19  = MUL(in[8]  - in[23], costab17); */
	butterfly2_in	r0/*t2*/, r1/*t18*/, r2/*t3*/, r3/*t19*/, r12, 7, 24, 8, 23, costab15, costab17, r10, r11

/*	t42  = t18 + t19;
	t60  = MUL(t18 - t19, costab30);
	t34  = t2  + t3;
	t51  = MUL(t2  - t3,  costab30); */
	butterfly2	r1/*t42*/, r3/*t60*/, r0/*t34*/, r2/*t51*/, costab30, r10, r11, lr

/*	t73  = t41 + t42;  t94  = MUL(t41 - t42, costab4);
	t83  = t59 + t60;  t106 = MUL(t59 - t60, costab4); */


/*	t69  = t33 + t34;  t89  = MUL(t33 - t34, costab4);
	t78  = t50 + t51;  t100 = MUL(t50 - t51, costab4); */
	butterfly4	r5/*t73*/, r1/*t94*/, r7/*t83*/, r3/*t106*/,r4/*t69*/, r0/*t89*/, r6/*t78*/, r2/*t100*/, costab4, r10, r11, lr

/*	Store away the computed butterflies:
	sp[0-7] = t83, t78, t73, t69, t106, t100, t94, t89 */
	stm	sp, r0-r7


/*	t4   = in[3]  + in[28];  t20  = MUL(in[3]  - in[28], costab7);
	t5   = in[12] + in[19];  t21  = MUL(in[12] - in[19], costab25); */
	butterfly2_in	r4/*t4*/, r5/*t20*/, r6/*t5*/, r7/*t21*/, r12, 3, 28, 12, 19, costab7, costab25, r10, r11

/*	t43  = t20 + t21;
	t61  = MUL(t20 - t21, costab14);
	t35  = t4  + t5;
	t52  = MUL(t4  - t5,  costab14); */
	butterfly2	r5/*t43*/, r7/*t61*/, r4/*t35*/, r6/*t52*/, costab14, r10, r11, lr

/*	t6   = in[4]  + in[27];  t22  = MUL(in[4]  - in[27], costab9);
	t7   = in[11] + in[20];  t23  = MUL(in[11] - in[20], costab23); */
	butterfly2_in	r0/*t6*/, r1/*t22*/, r2/*t7*/, r3/*t23*/, r12, 4, 27, 11, 20, costab9, costab23, r10, r11

/*	t44  = t22 + t23;
	t62  = MUL(t22 - t23, costab18);
	t36  = t6  + t7;
	t53  = MUL(t6  - t7,  costab18); */
	butterfly2	r1/*t44*/, r3/*t62*/, r0/*t36*/, r2/*t53*/, costab18, r10, r11, lr

/*	t74  = t43 + t44;  t95  = MUL(t43 - t44, costab28);
	t84  = t61 + t62;  t107 = MUL(t61 - t62, costab28); */

/*	t70  = t35 + t36;  t90  = MUL(t35 - t36, costab28);
	t79  = t52 + t53;  t101 = MUL(t52 - t53, costab28); */
	butterfly4	r5/*t74*/, r1/*t95*/, r7/*t84*/, r3/*t107*/, r4/*t70*/, r0/*t90*/, r6/*t79*/, r2/*t101*/, costab28, r10, r11, lr

/*	Store away the computed butterflies:
	sp[8-15] = t84, t79, t74, t70, t107, t101, t95, t90 */
	sub	r10, sp, -8*4
	stm	r10, r0-r7


/*	t8   = in[1]  + in[30];  t24  = MUL(in[1]  - in[30], costab3);
	t9   = in[14] + in[17];  t25  = MUL(in[14] - in[17], costab29); */
	butterfly2_in	r4/*t8*/, r5/*t24*/, r6/*t9*/, r7/*t25*/, r12, 1, 30, 14, 17, costab3, costab29, r10, r11


/*	t45  = t24 + t25;
	t63  = MUL(t24 - t25, costab6);
	t37  = t8  + t9;
	t54  = MUL(t8  - t9,  costab6); */
	butterfly2	r5/*t45*/, r7/*t63*/, r4/*t37*/, r6/*t54*/, costab6, r10, r11, lr

/*	t10  = in[6]  + in[25];  t26  = MUL(in[6]  - in[25], costab13);
	t11  = in[9]  + in[22];  t27  = MUL(in[9]  - in[22], costab19); */
	butterfly2_in	r0/*t10*/, r1/*t26*/, r2/*t11*/, r3/*t27*/, r12, 6, 25, 9, 22, costab13, costab19, r10, r11

/*	t46  = t26 + t27;
	t64  = MUL(t26 - t27, costab26);
	t38  = t10 + t11;
	t55  = MUL(t10 - t11, costab26); */
	butterfly2	r1/*t46*/, r3/*t64*/, r0/*t38*/, r2/*t55*/, costab26, r10, r11, lr

/*	t75  = t45 + t46;  t96  = MUL(t45 - t46, costab12);
	t85  = t63 + t64;  t108 = MUL(t63 - t64, costab12); */

/*	t71  = t37 + t38;  t91  = MUL(t37 - t38, costab12);
	t80  = t54 + t55;  t102 = MUL(t54 - t55, costab12); */
	butterfly4	r5/*t75*/, r1/*t96*/, r7/*t85*/, r3/*t108*/, r4/*t71*/, r0/*t91*/, r6/*t80*/, r2/*t102*/, costab12, r10, r11, lr

/*	Store away the computed butterflies:
	sp[16-23] = t85, t80, t75, t71, t108, t102, t96, t91 */
	sub	r10, sp, -16*4
	stm	r10, r0-r7

/*	t12  = in[2]  + in[29];  t28  = MUL(in[2]  - in[29], costab5);
	t13  = in[13] + in[18];  t29  = MUL(in[13] - in[18], costab27); */
	butterfly2_in	r4/*t12*/, r5/*t28*/, r6/*t13*/, r7/*t29*/, r12, 2, 29, 13, 18, costab5, costab27, r10, r11

/*	t47  = t28 + t29;
	t65  = MUL(t28 - t29, costab10);
	t39  = t12 + t13;
	t56  = MUL(t12 - t13, costab10); */
	butterfly2	r5/*t47*/, r7/*t65*/, r4/*t39*/, r6/*t56*/, costab10, r10, r11, lr

/*	t14  = in[5]  + in[26];  t30  = MUL(in[5]  - in[26], costab11);
	t15  = in[10] + in[21];  t31  = MUL(in[10] - in[21], costab21);*/
	butterfly2_in	r0/*t14*/, r1/*t30*/, r2/*t15*/, r3/*t31*/, r12, 5, 26, 10, 21, costab11, costab21, r10, r11

/*	t48  = t30 + t31;
	t66  = MUL(t30 - t31, costab22);
	t40  = t14 + t15;
	t57  = MUL(t14 - t15, costab22);*/
	butterfly2	r1/*t48*/, r3/*t66*/, r0/*t40*/, r2/*t57*/, costab22, r10, r11, lr

/*	t76  = t47 + t48;  t97  = MUL(t47 - t48, costab20);
	t86  = t65 + t66;  t109 = MUL(t65 - t66, costab20);*/

/*	t72  = t39 + t40;  t92  = MUL(t39 - t40, costab20);
	t81  = t56 + t57;  t103 = MUL(t56 - t57, costab20);*/
	butterfly4	r5/*t76*/, r1/*t97*/, r7/*t86*/, r3/*t109*/,r4/*t72*/, r0/*t92*/, r6/*t81*/, r2/*t103*/, costab20, r10, r11, lr

/*	Store away the computed butterflies:
	sp[24-31] = t86, t81, t76, t72, t109, t103, t97, t92 */
	sub	r10, sp, -24*4
	stm	r10, r0-r7

/*      We now have the following on the stack:

	sp[0-7] = t83, t78, t73, t69, t106, t100, t94, t89
	sp[8-15] = t84, t79, t74, t70, t107, t101, t95, t90
	sp[16-23] = t85, t80, t75, t71, t108, t102, t96, t91
	sp[24-31] = t86, t81, t76, t72, t109, t103, t97, t92 	*/

/*	Load 	{r0...r7} = { t72, t76, t71, t75, t70, t74, t69, t73 } */
	ld.d	r6, sp[2*4]
	ld.d	r4, sp[10*4]
	ld.d	r2, sp[18*4]
	ld.d	r0, sp[26*4]


/*	t113 = t69  + t70;
	t141 = MUL(t69 - t70, costab8);

	t115 = t73  + t74;
	t144 = MUL(t73 - t74, costab8); */
	butterfly2	r6/*t113*/, r4/*t141*/, r7/*t115*/, r5/*t144*/, costab8, r10, r11, lr

/*	t114 = t71  + t72;
	t142 = MUL(t71 - t72, costab24);

	t116 = t75  + t76;
	t145 = MUL(t75 - t76, costab24); */
	butterfly2	r2/*t114*/, r0/*t142*/, r3/*t116*/, r1/*t145*/, costab24, r10, r11, lr


/*
	t191 = t113 + t114;
	t192 = MUL(t113 - t114, costab16)

	t32  = t115 + t116;
	t177 = MUL(t115 - t116, costab16) ;

	t143 = t141 + t142;
	t190 = MUL(t141 - t142, costab16) ;

	t146 = t144 + t145;
	t184 = MUL(t144 - t145, costab16) ; */
	butterfly4	r6/*t191*/, r2/*t192*/, r7/*t32*/, r3/*t177*/, r4/*t143*/, r0/*190*/, r5/*t146*/, r1/*t184*/, costab16, r10, r11, lr

/*	Store away the computed butterflies:
	sp[2-3] = t32, t191
	sp[10-11] = t146, t143
	sp[18-19] = t177, t192
	sp[26-27] = t184, t190 */
	st.d	sp[2*4] , r6
	st.d	sp[10*4], r4
	st.d	sp[18*4], r2
	st.d	sp[26*4], r0

/*	Load 	{r0...r7} = { t81, t86, t80, t85, t79, t84, t78, t83 } */
	ld.d	r6, sp[0*4]
	ld.d	r4, sp[8*4]
	ld.d	r2, sp[16*4]
	ld.d	r0, sp[24*4]


/*	t118 = t78  + t79;
	t148 = MUL(t78 - t79, costab8);

	t121 = t83  + t84;
	t152 = MUL(t83 - t84, costab8); */
	butterfly2	r6/*t118*/, r4/*t148*/, r7/*t121*/, r5/*t152*/, costab8, r10, r11, lr

/*	t119 = t80  + t81;
	t149 = MUL(t80 - t81, costab24);

	t122 = t85  + t86;
	t153 = MUL(t85 - t86, costab24); */
	butterfly2	r2/*t119*/, r0/*t149*/, r3/*t122*/, r1/*t153*/, costab24, r10, r11, lr



/*	t58  = t118 + t119;
	t178 = MUL(t118 - t119, costab16) ;

	t67  = t121 + t122;
	t179 = MUL(t121 - t122, costab16) ;

	t150 = t148 + t149;
	t185 = MUL(t148 - t149, costab16) ;

	t154 = t152 + t153;
	t186 = MUL(t152 - t153, costab16) ; */
	butterfly4	r6/*t58*/, r2/*t178*/, r7/*t67*/, r3/*t179*/, r4/*t150*/, r0/*185*/, r5/*t154*/, r1/*t186*/, costab16, r10, r11, lr

/*	Store away the computed butterflies:
	sp[0-1] = t67, t58
	sp[8-9] = t154, t150
	sp[16-17] = t179, t178
	sp[24-25] = t186, t185 */
	st.d	sp[0*4] , r6
	st.d	sp[8*4], r4
	st.d	sp[16*4], r2
	st.d	sp[24*4], r0

/*	Load 	{r0...r7} = { t92, t97, t91, t96, t90, t95, t89, t94 } */
	ld.d	r6, sp[6*4]
	ld.d	r4, sp[14*4]
	ld.d	r2, sp[22*4]
	ld.d	r0, sp[30*4]


/*	t125 = t89  + t90;
	t157 = MUL(t89 - t90, costab8);

	t128 = t94  + t95;
	t161 = MUL(t94 - t95, costab8); */
	butterfly2	r6/*t125*/, r4/*t157*/, r7/*t128*/, r5/*t161*/, costab8, r10, r11, lr

/*	t126 = t91  + t92;
	t158 = MUL(t91 - t92, costab24);

	t129 = t96  + t97;
	t162 = MUL(t96 - t97, costab24); */
	butterfly2	r2/*t126*/, r0/*t158*/, r3/*t129*/, r1/*t162*/, costab24, r10, r11, lr


/*
	t93  = t125 + t126;
	t180 = MUL(t125 - t126, costab16) ;

	t98  = t128 + t129;
	t181 = MUL(t128 - t129, costab16) ;

	t159 = t157 + t158;
	t187 = MUL(t157 - t158, costab16) ;

	t163 = t161 + t162;
	t188 = MUL(t161 - t162, costab16) ; */
	butterfly4	r6/*t93*/, r2/*t180*/, r7/*t98*/, r3/*t181*/, r4/*t159*/, r0/*187*/, r5/*t163*/, r1/*t188*/, costab16, r10, r11, lr


/*	Store away the computed butterflies:
	sp[6-7] = t98, t93
	sp[14-15] = t163, t159
	sp[22-23] = t181, t180
	sp[30-31] = t188, t187 */
	st.d	sp[6*4] , r6
	st.d	sp[14*4], r4
	st.d	sp[22*4], r2
	st.d	sp[30*4], r0

/*	Load 	{r0...r7} = { t103, t109, t102, t108, t101, t107, t100, t106 } */
	ld.d	r6, sp[4*4]
	ld.d	r4, sp[12*4]
	ld.d	r2, sp[20*4]
	ld.d	r0, sp[28*4]



/*	t132 = t100 + t101;
	t166 = MUL(t100 - t101, costab8);

	t136 = t106 + t107;
	t171 = MUL(t106 - t107, costab8); */
	butterfly2	r6/*t132*/, r4/*t166*/, r7/*t136*/, r5/*t171*/, costab8, r10, r11, lr

/*	t133 = t102 + t103;
	t167 = MUL(t102 - t103, costab24);

	t137 = t108 + t109;
	t172 = MUL(t108 - t109, costab24);*/
	butterfly2	r2/*t133*/, r0/*t167*/, r3/*t137*/, r1/*t172*/, costab24, r10, r11, lr


/*	t104 = t132 + t133;
	t182 = MUL(t132 - t133, costab16) ;

	t110 = t136 + t137;
	t183 = MUL(t136 - t137, costab16) ;

	t168 = t166 + t167;
	t189 = MUL(t166 - t167, costab16) ;

	t173 = t171 + t172;
	t208 = MUL(t171 - t172, costab16) ; */
	butterfly4	r6/*t104*/, r2/*t182*/, r7/*t110*/, r3/*t183*/, r4/*t168*/, r0/*189*/, r5/*t173*/, r1/*t208*/, costab16, r10, r11, lr

/*	Store away the computed butterflies:
	sp[4-5] = t110, t104
	sp[12-13] = t173, t168
	sp[20-21] = t183, t182
	sp[28-29] = t208, t189 */
	st.d	sp[4*4] , r6
	st.d	sp[12*4], r4
	st.d	sp[20*4], r2
	st.d	sp[28*4], r0

/*	Now we have the following stack

	sp[0-7]   = t67,  t58 , t32,  t191, t110, t104, t98,  t93
	sp[8-15]  = t154, t150,	t146, t143, t173, t168,	t163, t159
	sp[16-23] = t179, t178,	t177, t192, t183, t182,	t181, t180
	sp[24-31] = t186, t185, t184, t190, t208, t189,	t188, t187
*/

	/* Get slot, lo and hi from stack */
	lddsp	lr, sp[32*4 + 4] /*slot*/
	lddsp	r12, sp[32*4 + 8] /*lo*/
	lddsp	r11, sp[32*4 + 12] /*hi*/

	add	r12, r12, lr << 2
	add	r11, r11, lr << 2


/*	t49  = -(t67 * 2) + t32;
	 hi[14][slot] = SHIFT(t32);
	t87  = -(t110 * 2) + t67;
	t138 = -(t173 * 2) + t110;
	t203 = -(t208 * 2) + t173; */

	lddsp	r0/*t67*/, sp[0]
	lddsp	r1/*t32*/, sp[2*4]
	lddsp	r2/*t110*/, sp[4*4]
	lddsp	r3/*t173*/, sp[12*4]
	lddsp	r5/*t208*/, sp[28*4]

	sub	r4/*t49*/, r1, r0 << 1
	scale	r1
	sub	r0/*t87*/, r0, r2 << 1
	st.w	r11[14*SLOTS*4], r1
	sub	r2/*t138*/, r2, r3 << 1
	sub	r1/*t203*/, r3, r5 << 1

/*      Live:	r0 = t87, r1= t203, r2= t138, r4 = t49
	Free:	r3, r5, r6, r7, r8, r9, r10, lr  */

/*	t68  = (t98 * 2) + t49;
	hi[12][slot] = SHIFT(-t49);
	t130 = -(t163 * 2) + t98;
	t201 = -(t188 * 2) + t163;
	t200 = -(t186 * 2) + t154;
	t111 = (t154 * 2) + t87;
	t77  = -(-(t87 * 2) - t68);
	t88  = (t146 * 2) + t77;
	t199 = -(t184 * 2) + t146;
	hi[ 8][slot] = SHIFT(-t77);
	hi[10][slot] = SHIFT(t68);*/
	lddsp	r3/*t98*/, sp[6*4]
	lddsp	r5/*t163*/, sp[14*4]
	lddsp	r6/*t188*/, sp[30*4]
	lddsp	r10/*t186*/, sp[24*4]

	add	r7/*t68*/, r4, r3 << 1
	neg	r4
	scale	r4
	lddsp	r9/*t154*/, sp[8*4]
	sub	r3/*t130*/, r3, r5 << 1
	st.w	r11[12*SLOTS*4], r4
	sub	r8/*t201*/, r5, r6 << 1
	sub	r4/*t200*/, r9, r10 << 1
	lddsp	lr/*t146*/, sp[10*4]
	lddsp	r6/*t184*/, sp[26*4]
	add	r10/*t111*/, r0, r9 << 1
	add	r5/*t77*/,r7, r0 << 1
	add	r0/*t88*/, r5, lr << 1
	sub	r6/*t199*/, lr, r6 << 1
	neg	r5
	scale	r5
	scale	r7
	st.w	r11[8*SLOTS*4], r5
	st.w	r11[10*SLOTS*4], r7

/*      Live:	r0 = t88, r1= t203, r2= t138, r3 = t130, r4 = t200,
		r6 = 199, r8 = t201, r10 = t111
	Free:	r5, r7, r9, lr    */


/*
	t123 = -(-(t138 * 2) - t111);
	t174 = (t183 * 2) + t138;
	t99  = -(t111 * 2) + t88;
	hi[ 6][slot] = SHIFT(t88); */
	lddsp	r5/*t183*/, sp[20*4]

	add	r7/*t123*/, r10, r2 << 1
	sub	r10/*t99*/, r0, r10 << 1
	scale	r0
	add	r2/*t174*/, r2, r5 << 1
	st.w	r11[6*SLOTS*4], r0

/*      Live:	r1 = t203, r2 = t174, r3 = t130, r4 = t200,
		r6 = t199, r7 = t123, r8 = t201, r10 = t99
	Free:	r0, r5, r9, lr    */

/*	t112 = -(t130 * 2) + t99;
	t164 = (t181 * 2) + t130;
	hi[ 4][slot] = SHIFT(-t99); */
	lddsp	r0/*t181*/, sp[22*4]

	sub	r5/*t112*/, r10, r3 << 1
	neg	r10
	scale	r10
	add	r3/*164*/, r3, r0 << 1
	st.w	r11[4*SLOTS*4], r10

/*      Live:	r1 = t203, r2 = t174, r3 = t164, r4 = t200,
		r5 = t112, r6 = t199, r7 = t123, r8 = t201
	Free:	r0, r9, r10, lr    */


/*	t117 = -(-(t123 * 2) - t112);
	t139 = (t179 * 2) + t123;
	hi[ 2][slot] = SHIFT(t112); */
	lddsp	r0/*t179*/, sp[16*4]

	add	r9/*t117*/, r5, r7 << 1
	scale	r5
	add	r7/*t139*/, r7, r0 << 1
	st.w	r11[2*SLOTS*4], r5

/*      Live:	r1 = t203, r2 = t174, r3 = t164, r4 = t200,
		r6 = t199, r7 = t139, r8 = t201, r9 = t117
	Free:	r0, r5, r10, lr    */

/*	t155 = -(t174 * 2) + t139;
	t204 = -(-(t203 * 2) - t174);
	t124 = (t177 * 2) + t117;
	hi[ 0][slot] = SHIFT(-t117);
	t131 = -(t139 * 2) + t124;
	lo[ 1][slot] = SHIFT(t124);*/
	lddsp	r0/*t177*/, sp[18*4]

	sub	r5/*t155*/, r7, r2 << 1
	add	r2/*t204*/, r2, r1 << 1
	add	r0/*t124*/, r9, r0 << 1
	neg	r9
	scale	r9
	sub	r7/*t131*/, r0, r7 << 1
	scale	r0
	st.w	r11[0*SLOTS*4], r9
	st.w	r12[1*SLOTS*4], r0

/*      Live:	r2 = t204, r3 = t164, r4 = t200,
		r5 = t155, r6 = t199, r7 = t131, r8 = t201
	Free:	r0, r1, r9, r10, lr    */

/*	t140 = (t164 * 2) + t131;
	lo[ 3][slot] = SHIFT(-t131);
	t202 = -(-(t201 * 2) - t164);  */
	add	r0/*t140*/, r7, r3 << 1
	neg	r7
	scale	r7
	add	r3/*t202*/, r3, r8 << 1
	st.w	r12[3*SLOTS*4], r7

/*      Live:	r0 = t140, r2 = t204, r3 = t202, r4 = t200,
		r5 = t155, r6 = t199
	Free:	r1, r7, r8, r9, r10, lr    */


/*	t147 = -(-(t155 * 2) - t140);
	lo[ 5][slot] = SHIFT(t140);
	t175 = -(t200 * 2) + t155;
	t156 = -(t199 * 2) + t147;
	lo[ 7][slot] = SHIFT(-t147); */
	add	r1/*t147*/, r0, r5 << 1
	scale	r0
	sub	r5/*t175*/, r5, r4 << 1
	sub	r4/*156*/, r1, r6 << 1
	neg	r1
	scale	r1
	st.w	r12[5*SLOTS*4], r0
	st.w	r12[7*SLOTS*4], r1

/*      Live:	r2 = t204, r3 = t202,
		r4 = t156, r5 = t175
	Free:	r0, r1, r6, r7, r8, r9, r10, lr    */


/*	t205 = -(-(t204 * 2) - t175);
	t165 = -(t175 * 2) + t156;
	lo[ 9][slot] = SHIFT(t156);
	t176 = -(t202 * 2) + t165;
	lo[11][slot] = SHIFT(-t165);
	t206 = -(-(t205 * 2) - t176);
	lo[15][slot] = SHIFT(-t206)
	lo[13][slot] = SHIFT(t176) */
	add	r0/*t205*/, r5, r2 << 1
	sub	r1/*t165*/, r4, r5 << 1
	scale	r4
	sub	r3/*t176*/, r1, r3 << 1
	st.w	r12[9*SLOTS*4], r4
	neg	r1
	scale	r1
	add	r6/*t206*/, r3, r0 << 1
	neg	r6
	scale	r6
	scale	r3
	st.w	r12[11*SLOTS*4], r1
	st.w	r12[15*SLOTS*4], r6
	st.w	r12[13*SLOTS*4], r3

/*	t193 = -((t190 * 2) - t143)
	hi[ 7][slot] = SHIFT(t143);
	lo[ 8][slot] = SHIFT(-t193);
	t82  = -(t104 * 2) + t58;
	hi[13][slot] = SHIFT(t58);
	t134 = -(t168 * 2) + t104;
	t196 = -(t189 * 2) + t168; */

	lddsp	r0/*t190*/, sp[27*4]
	lddsp	r1/*t143*/, sp[11*4]
	lddsp	r2/*t104*/, sp[5*4]
	lddsp	r3/*t58*/, sp[1*4]
	lddsp	r4/*t168*/, sp[13*4]
	lddsp	r5/*t189*/, sp[29*4]
	sub	r0/*t193*/, r1, r0 << 1
	neg	r0
	scale	r1
	scale	r0
	st.w	r11[7*SLOTS*4], r1
	st.w	r12[8*SLOTS*4], r0
	sub	r0/*t82*/, r3, r2 << 1
	scale	r3
	sub	r2/*t134*/, r2, r4 << 1
	sub	r4/*t196*/, r4, r5 << 1
	st.w	r11[13*SLOTS*4], r3

/*      Live:	r0 = t82, r2 = t134,
		r4 = t196
	Free:	r1, r3, r5, r6, r7, r8, r9, r10, lr    */



/*

	t207 = -(t185 * 2) + t150;
	t105 = (t150 * 2) + t82;
	hi[ 9][slot] = SHIFT(-t82);
	t120 = -(-(t134 * 2) - t105);
	hi[ 5][slot] = SHIFT(t105);
	t169 = (t182 * 2) + t134;

	t135 = (t178 * 2) + t120;
	hi[ 1][slot] = SHIFT(-t120);
	t197 = -(-(t196 * 2) - t169);
	t151 = -(t169 * 2) + t135;
	lo[ 2][slot] = SHIFT(t135); */
	lddsp	r1/*t185*/, sp[25*4]
	lddsp	r3/*t150*/, sp[9*4]
	lddsp	r5/*t182*/, sp[21*4]
	lddsp	r8/*t178*/, sp[17*4]

	sub	r6/*t207*/, r3, r1 << 1
	add	r3/*t105*/, r0, r3 << 1
	neg	r0
	scale	r0
	add	r7/*t120*/, r3, r2 << 1
	scale	r3
	st.w	r11[9*SLOTS*4], r0
	st.w	r11[5*SLOTS*4], r3
	add	r2/*t169*/, r2, r5 << 1
	add	r8/*t135*/, r7, r8 << 1
	neg	r7
	scale	r7
	add	r4/*t197*/, r2, r4 << 1
	sub	r2/*t151*/, r8, r2 << 1
	scale	r8
	st.w	r11[1*SLOTS*4], r7
	st.w	r12[2*SLOTS*4], r8

/*      Live:	r2 = t151, r4 = t197, r6 = t207

	Free:	r0, r1, r3, r5, r7, r8, r9, r10, lr    */



/*	t170 = -(t207 * 2) + t151;
	lo[ 6][slot] = SHIFT(-t151);

	t198 = -(-(t197 * 2) - t170);
	lo[10][slot] = SHIFT(t170);
	lo[14][slot] = SHIFT(-t198);

	t127 = -(t159 * 2) + t93;
	hi[11][slot] = SHIFT(t93);
	t194 = -(t187 * 2) + t159;   */
	lddsp	r0/*t159*/, sp[15*4]
	lddsp	r1/*t93*/, sp[7*4]
	lddsp	r3/*t187*/, sp[31*4]
	sub	r5/*t170*/, r2, r6 << 1
	neg	r2
	scale	r2
	add	r4/*t198*/,r5, r4 << 1
	neg	r4
	scale	r5
	scale	r4
	st.w	r12[6*SLOTS*4], r2
	st.w	r12[10*SLOTS*4], r5
	st.w	r12[14*SLOTS*4], r4
	sub	r7/*t127*/, r1, r0 << 1
	scale	r1
	sub	r0/*t194*/, r0, r3 << 1
	st.w	r11[11*SLOTS*4], r1


/*      Live:	r0 = t194, r7 = t127
	Free:	r1, r2, r3, r4, r6, r5, r8, r9, r10, lr    */

/*	t160 = (t180 * 2) + t127;
	hi[ 3][slot] = SHIFT(-t127);
	t195 = -(-(t194 * 2) - t160);
	lo[ 4][slot] = SHIFT(t160);
	lo[12][slot] = SHIFT(-t195);

	hi[15][slot] = SHIFT(t191);
	lo[ 0][slot] = SHIFT(t192); */
	lddsp	r1/*t180*/, sp[23*4]
	lddsp	r2/*t191*/, sp[3*4]
	lddsp	r3/*t192*/, sp[19*4]
	add	r4/*t160*/, r7, r1 << 1
	neg	r7
	scale	r7
	add	r6/*t195*/, r4, r0 << 1
	scale	r4
	neg	r6
	scale	r6
	st.w	r11[3*SLOTS*4], r7
	st.w	r12[4*SLOTS*4], r4
	st.w	r12[12*SLOTS*4], r6
	scale	r2
	scale	r3
	st.w	r11[15*SLOTS*4], r2
	st.w	r12[0*SLOTS*4], r3

	sub	sp, -32*4
	ldm	sp++,r0-r7, r9-r11, pc
