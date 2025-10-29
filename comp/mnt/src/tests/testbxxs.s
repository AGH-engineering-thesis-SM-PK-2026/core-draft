.global _start
.text

/* branch signed */
/* if any test fails register "ra" will contain index of such failed test 
 * and "s0" will be set to 1 */

_start:
	li ra, 0
    li s0, 0
	li a0, 1
	li a1, 1
    li a2, 2
	li a3, -1

	li ra, 1 /* test: -1 != -1 */
    bne a3, a3, bad_cpu /* skip */
    li ra, 2 /* test: 0 != -1 */
	bne zero, a3, bne_ok /* take */
	j bad_cpu
bne_ok:
	li ra, 3 /* test: 0 == -1 */
    beq zero, a3, bad_cpu /* skip */
	li ra, 4 /* test: 1 == 1 */
	beq a0, a1, beq_ok /* take */
	j bad_cpu
beq_ok:
	li ra, 5 /* test: 1 < 1 */
	blt a0, a1, bad_cpu /* skip */
	li ra, 6 /* test: 2 < -1 */
	blt a2, a3, bad_cpu /* skip */
 	li ra, 7 /* test: 2 < 1 */
	blt a2, a1, bad_cpu /* skip */
	li ra, 8 /* test: -1 < 2 */
	blt a3, a2, blt_i1 /* tak */    
    j bad_cpu
blt_i1:
	li ra, 9 /* test: 1 < 2 */
	blt a1, a2, blt_ok /* take */
	j bad_cpu
blt_ok:
	li ra, 10 /* test: 1 > 1 */
	bgt a0, a1, bad_cpu /* skip */
	li ra, 11 /* test: -1 > 2 */
	bgt a3, a2, bad_cpu /* skip */
 	li ra, 12 /* test: 1 > 2 */
	bgt a1, a2, bad_cpu /* skip */
	li ra, 13 /* test: 2 > -1 */
	bgt a2, a3, bgt_i1 /* take */
    j bad_cpu
bgt_i1:
 	li ra, 14 /* test: 2 > 1 */
	bgt a2, a1, bgt_ok /* take */
	j bad_cpu
bgt_ok:
	li ra, 15 /* test: 1 <= 1 */
	ble a0, a1, ble_i1 /* take */
	j bad_cpu
ble_i1:    
	li ra, 16 /* test: 1 <= 1 */
	ble a2, a1, bad_cpu /* skip */
	li ra, 17 /* test: 2 <= -1 */
	ble a2, a3, bad_cpu /* skip */
	li ra, 18 /* test: -1 <= 2 */
	ble a3, a2, ble_i2 /* take */
	j bad_cpu
ble_i2:
	li ra, 19 /* test: 1 <= 2 */
	ble a1, a2, ble_ok /* take */
    j bad_cpu
ble_ok:
	li ra, 20 /* test: 1 >= 1 */
	bge a0, a1, bge_i1 /* take */
	j bad_cpu
bge_i1:    
	li ra, 21 /* test: 1 >= 2 */
	bge a1, a2, bad_cpu /* skip */
	li ra, 22 /* test: -1 >= 2 */
	bge a3, a2, bad_cpu /* skip */
	li ra, 23 /* test: 2 >= -1 */
	bge a2, a3, bge_i2 /* take */ 
	j bad_cpu
bge_i2:
	li ra, 24 /* test: 2 >= 1 */
	bge a2, a1, bge_ok /* take */
    j bad_cpu
bge_ok:
ok:
	j ok
bad_cpu:
	li s0, 1
	j bad_cpu