DATA	SEGMENT
DELIVERY_NUMS	DB	102, 90, 67, 89, 98, 125
STANDARD_NUMS	DB	80
WAGE_1	DW	600	;整数部分
WAGE_2	DB	0	;小数部分
MORE	DB	0
LESS	DB	0
TO_OUTPUT	DB	5 DUP(?)

DATA	ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA
MAIN	PROC	FAR
	PUSH	DS
	MOV	AX, 0
	PUSH	AX
	
	MOV	AX, DATA
	MOV	DS, AX
	
	CALL	JUDGE			;超量和不足储存于MORE以及LESS中
	CALL	CALCULATE		;计算最终工资，结果为 WAGE_1.WAGE_2
	CALL	OUTPUT			;输出
	
	RET
MAIN	ENDP

JUDGE	PROC	NEAR			;计算快递量与达标量的差异
	PUSH	AX
	PUSH	BX
	PUSH	CX
	
	MOV	BX, OFFSET DELIVERY_NUMS
	MOV	CX, 6		;6天
	
START_OF_JUDGE:
	MOV	AL, BYTE PTR [BX]
	CMP	AL, STANDARD_NUMS
	JGE	MORE_THAN
	JMP	LESS_THAN
	
MORE_THAN:
	;AL>STANDARD_NUMS
	MOV	AH, AL
	SUB	AH, STANDARD_NUMS
	ADD	MORE, AH
	JMP	END_OF_JUDGE
	
LESS_THAN:
	;AL<STANDARD_NUMS
	MOV	AH, STANDARD_NUMS
	SUB	AH, BYTE PTR [BX]
	ADD	LESS, AH
	
END_OF_JUDGE:
	INC	BX
	DEC	CX
	CMP	CX, 0
	JNE	START_OF_JUDGE
	
	POP	CX
	POP	BX
	POP	AX
	RET
JUDGE	ENDP

CALCULATE	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	
	MOV	AH, 0
	MOV	CH, 0
	MOV	AL, MORE
	MOV	CL, LESS
	;AX->MORE,CX->LESS
	
	ADD	WAGE_1, AX
	SUB	WAGE_1, CX
	
PLUS_MORE:
	;WAGE+=AX/2
	MOV	BH, 2
	DIV	BH
	;AL->商 AH->余数
	MOV	DH, 0
	MOV	DL, AL
	ADD	WAGE_1, DX
	CMP	AH, 0
	JE	MINUS_LESS	
	ADD	WAGE_2, 5		;小数部分为0.5!
	
MINUS_LESS:
	;WAGE+=CX/5
	MOV	AX, CX
	MOV	BH, 5
	DIV	BH
	;AL->商 AH->余数
	MOV	DH, 0
	MOV	DL, AL
	SUB	WAGE_1, DX
	CMP	AH, 0
	JE	END_OF_CALCULATE
	MOV	AL, AH
	MOV	AH, 0
	MOV	BH, 2
	MUL	BH
	;AL此时储存需要减去的小数部分
	CMP	BYTE PTR WAGE_2, AL
	JL	CARRY			;借位
	SUB	BYTE PTR WAGE_2, AL
	JMP	END_OF_CALCULATE
	
CARRY:
	DEC	WAGE_1
	ADD	WAGE_2, 10
	SUB	BYTE PTR WAGE_2, AL

END_OF_CALCULATE:
	POP	CX
	POP	BX
	POP	AX
	
	RET
CALCULATE	ENDP

OUTPUT	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	
	;输出WAGE1.WAGE2 WAGE1->WORD WAGE2->BYTE
	;默认工资整数部分有3位，小数部分有1位
	
	MOV	BX, OFFSET TO_OUTPUT
	MOV	AX, WAGE_1
	MOV	CH, 100
	DIV	CH
	;AL->商 AH->余数
	MOV	BYTE PTR [BX], AL
	ADD	BYTE PTR [BX], '0'	;百位OK
	INC	BX
	
	MOV	AL, AH
	MOV	AH, 0
	MOV	CH, 10
	DIV	CH
	MOV	BYTE PTR [BX], AL
	ADD	BYTE PTR [BX], '0'	;十位OK
	INC	BX
	
	MOV	BYTE PTR [BX], AH
	ADD	BYTE PTR [BX], '0'	;个位OK
	INC	BX
	
	MOV	BYTE PTR [BX], '.'	;小数点OK
	INC	BX
	
	MOV	AL, BYTE PTR WAGE_2
	MOV	BYTE PTR [BX], AL
	ADD	BYTE PTR [BX], '0'	;小数部分OK
	
	MOV	BX, OFFSET TO_OUTPUT
	MOV	CX, 5
	MOV	AH, 2
	
AGAIN_OF_OUTPUT:
	MOV	DL, BYTE PTR [BX]
	INT	21H
	
	INC	BX
	DEC	CX
	CMP	CX, 0
	JNE	AGAIN_OF_OUTPUT
	
END_OF_OUTPUT:
	POP	CX
	POP	BX
	POP	AX
	RET
OUTPUT	ENDP

CODE	ENDS
	END	MAIN