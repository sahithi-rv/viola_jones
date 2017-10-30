`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2017 13:00:16
// Design Name: 
// Module Name: cascadeclassifier
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module runCascadeClassifier(stages_thresh_array,stages_array,tree_thresh_array,rectangles_array,weights_array,alpha1_array,alpha2_array,flag);
localparam n_stages = 20;
localparam n_tree_thresh_array=100;
localparam n_rectangles_array=100;
localparam n_weights_array=100;
localparam n_alpha1_array=100;
localparam n_alpha2_array=100;

input [7:0] stages_thresh_array [0:n_stages-1];
input [7:0] stages_array [0:n_stages-1];
input [7:0] tree_thresh_array [0:n_tree_thresh_array-1];
input [7:0] rectangles_array [0:n_rectangles_array-1]; //3 rectangles * 4 per rectangle for four coordinates xylw 
input [7:0] weights_array [0:n_weights_array-1]; //3 arrays for each rectangle
input [7:0] alpha1_array [0:n_alpha1_array-1];
input [7:0] alpha2_array [0:n_alpha2_array-1];


output reg flag;

genvar i,j,temp,r_index,w_index,tree_index;

//assign r_index=0;
//assign w_index=0;
//assign tree_index=0;
reg [3:0] reg_w_index;
reg [3:0] reg_tree_index;
reg [3:0] reg_r_index;
assign reg_w_index=4'b0;
assign reg_tree_index=4'b0;
assign reg_r_index=4'b0;
assign flag=1'b1;

for (i=0;i<n_stages;i++)
begin
    reg [7:0] stage_sum;
    assign stage_sum=0;
    assign temp=stages_array[i];
    assign r_index=reg_r_index;
    assign w_index=reg_w_index;
    assign tree_index=reg_tree_index;
     for (j=0;j<temp;j++)
            begin
                reg [7:0] sum;
                assign sum=((rectangles_array[r_index]-rectangles_array[r_index+1]-rectangles_array[r_index+2]+rectangles_array[r_index+3])*weights_array[w_index])+((rectangles_array[r_index+4]-rectangles_array[r_index+5]-rectangles_array[r_index+6]+rectangles_array[r_index+7])*weights_array[w_index+1])+((rectangles_array[r_index+8]-rectangles_array[r_index+9]-rectangles_array[r_index+10]+rectangles_array[r_index+11])*weights_array[w_index+2]);
                always@(*)begin
                if (sum>=tree_thresh_array[tree_index])
                begin stage_sum=stage_sum+alpha2_array[tree_index];end
                else 
                begin stage_sum=stage_sum+alpha1_array[tree_index];end
                reg_w_index=reg_w_index+4'b0011;
                reg_r_index=reg_r_index+4'b1100;    
                end
            end
       always@(*) begin
       if(stage_sum<stages_thresh_array[i])
       begin
       flag=0;
      // i=n_stages;
       end
       end
end
endmodule